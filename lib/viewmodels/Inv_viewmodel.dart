import 'dart:ui';
import 'dart:async';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:investment_tracking/exceptions/Server_unavailable_exception.dart';
import 'package:investment_tracking/exceptions/Unauthorized_exception.dart';
import 'package:investment_tracking/models/transaction.dart';
import 'package:investment_tracking/repositories/Transaction_repository.dart';
import 'package:investment_tracking/repositories/session_repository.dart';
import 'package:investment_tracking/service/SettingsService.dart';
import 'package:investment_tracking/utils/app_strings.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/item.dart';
import '../models/user.dart';
import '../models/category.dart';
import '../repositories/item_repository.dart';
import '../repositories/auth_repository.dart';
import '../repositories/category_repository.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

// pra la conexion saber si esta conectado  hicimos flutter pub add connectivity_plus
/// ViewModel principal que gestiona el estado de la interfaz de inversiones.
class InvViewModel extends ChangeNotifier {
  final ItemRepository _itemRepo = ItemRepository();
  final AuthRepository _authRepo = AuthRepository();
  final TransactionRepository _transactionRepo = TransactionRepository();
  final CategoryRepository _categoryRepo = CategoryRepository();
  final SessionRepository _sessionRepo = SessionRepository();
  Timer? _heartbeatTimer;
  final SettingsService _settings = SettingsService();

  bool _isDarkMode = true;
  String _currentLocale = 'es';

  bool get isDarkMode => _isDarkMode;
  String get currentLocale => _currentLocale;
  User? currentUser;
  List<Item> itemList = [];
  List<Category> categories = [];
  bool isLoading = false;
  bool isOnline = true;
  bool sessionExpired = false;
  bool connectionLostNotification = false;
  bool syncSuccessNotification = false;
  bool syncFailureNotification = false;

  void clearSessionExpired() {
    sessionExpired = false;
  }

  void clearConnectionLostNotification() {
    connectionLostNotification = false;
  }

  void clearSyncSuccessNotification() {
    syncSuccessNotification = false;
  }

  void clearSyncFailureNotification() {
    syncFailureNotification = false;
  }

  Future<T?> _guarded<T>(Future<T> Function() fn) async {
    try {
      return await fn();
    } on UnauthorizedException {
      await logout();
      sessionExpired = true;
      notifyListeners();
      return null;
    }
  }

  InvViewModel() {
    _initConnectivityListener();
  }

  void _onServerUnavailable() {
    isOnline = false;
    _startRetryTimer();
  }

  void _startRetryTimer() {
    if (_heartbeatTimer?.isActive == true) return;
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 20), (_) {
      _checkRealConnection();
    });
  }

  Future<void> _checkRealConnection() async {
    try {
      final bool hasServer = await _authRepo.checkConnection().timeout(
        const Duration(seconds: 2),
      );
      if (hasServer) {
        if (!isOnline) {
          _heartbeatTimer?.cancel();
          _heartbeatTimer = null;
          isOnline = true;
          notifyListeners();
          if (currentUser != null) {
            final ok = await syncPendingData();
            if (ok) {
              syncSuccessNotification = true;
            } else {
              syncFailureNotification = true;
            }
            notifyListeners();
          }
        }
      } else {
        _onServerUnavailable();
      }
    } catch (_) {
      _onServerUnavailable();
    }
  }

  @override
  void dispose() {
    _heartbeatTimer?.cancel();
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  Future<bool> loadUserSession() async {
    final userId = await _sessionRepo.getUserId();
    if (userId == null) return false;
    currentUser = await _authRepo.loadUser();
    // if (currentUser == null) return false;
    // await fetchItems();
    return currentUser != null;
  }

  /// Autentica al usuario y prepara la sesión
  Future<bool> login(String username, String password) async {
    isLoading = true;
    notifyListeners();
    try {
      final result = await _authRepo.login(username, password);
      if (result != null) {
        await _sessionRepo.saveUserId(result.id);
        currentUser = result;
        isOnline = true;
        return true;
      }
      return false;
    } catch (e) {
      debugPrint("Error login: $e");
      isOnline = false;
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// ELIMINAR: Si falla el servidor, marca con is_deleted = 1
  Future<void> deleteTransaction(
    int? localId,
    int? serverId,
    int itemId,
  ) async {
    if (localId == null) return;
    if (currentUser == null) return;
    isLoading = true;
    notifyListeners();
    try {
      await _guarded(() async {
        final success = await _transactionRepo.deleteTransaction(
          localId,
          serverId,
          currentUser!.token,
        );
        await fetchItems();
        debugPrint(
          success ? "Eliminado con éxito" : "Marcado para borrar offline",
        );
      });
    } catch (e) {
      debugPrint("Error al borrar transacción: $e");
      _onServerUnavailable();
      await fetchItems();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> checkLocalSession() async {
    try {
      final response = await _authRepo.checkConnection().timeout(
        const Duration(seconds: 2),
        onTimeout: () => false,
      );
      isOnline = response;
    } catch (_) {
      isOnline = false;
    }
    notifyListeners();

    final savedUser = await _authRepo.loadUser();
    if (savedUser != null) {
      currentUser = savedUser;
      await fetchItems();
      return true;
    }
    return false;
  }

  /// Cierra la sesión y limpia las listas.
  Future<void> logout() async {
    await _sessionRepo.clearUserId();
    currentUser = null;
    itemList = [];
    categories = [];
    notifyListeners();
  }

  /// Carga el catálogo de categorías (usado en los dropdowns).
  Future<void> fetchCategories() async {
    if (currentUser == null) return;
    try {
      categories = await _categoryRepo.getAllCategories(currentUser!.token);
      notifyListeners();
    } catch (e) {
      debugPrint("Error cargando categorías: $e");
    }
  }

  /// MÉTODO PRINCIPAL DE CARGA: Sincroniza y refresca la lista de transacciones.
  Future<void> fetchItems() async {
    if (currentUser == null) return;
    isLoading = true;
    notifyListeners();
    try {
      await _guarded(() async {
        categories = await _categoryRepo.getAllCategories(currentUser!.token);
        itemList = await _itemRepo.fetchUserItems(
          currentUser!.id,
          currentUser!.token,
        );
      });
    } on ServerUnavailableException {
      itemList = await _itemRepo.getLocalItems(currentUser!.id);
      _onServerUnavailable();
    } catch (e) {
      debugPrint("Error en fetchItems: $e");
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshAll() => fetchItems();

  /// REGISTRO: Guarda un ítem y fuerza la actualización de la lista.
  Future<String> saveNewItem({
    required String name,
    required double stocks,
    required double price,
    required int categoryId,
  }) async {
    if (currentUser == null) {
      return AppStrings.get('transaction_error', currentLocale);
    }
    isLoading = true;
    notifyListeners();

    try {
      final result = await _guarded(() async {
        await _itemRepo.saveTransaction(
          name,
          stocks,
          price,
          categoryId,
          currentUser!.id,
          currentUser!.token,
        );
        await fetchItems();
        return AppStrings.get('transaction_success', currentLocale);
      });
      return result ?? AppStrings.get('session_expired', currentLocale);
    } catch (e) {
      debugPrint("Error saving item: $e");
      _onServerUnavailable();
      await fetchItems();
      return AppStrings.get('transaction_error', currentLocale);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<String> deleteItem(int localId, int? serverId) async {
    if (currentUser == null) return "Error: Sin sesión";
    isLoading = true;
    notifyListeners();
    try {
      final result = await _guarded(() async {
        final success = await _itemRepo.deleteItem(
          localId,
          serverId,
          currentUser!.token,
        );
        await fetchItems();
        return success ? "Eliminado" : "Marcado para borrar (Offline)";
      });
      return result ?? AppStrings.get('session_expired', currentLocale);
    } on ServerUnavailableException {
      _onServerUnavailable();
      await fetchItems();
      return "Marcado para borrar (Offline)";
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  ///Método para registraar un nuevo usuario
  Future<bool> register(String user, String pass, String email) async {
    isLoading = true;
    notifyListeners();

    final success = await _authRepo.register(user, pass, email);

    isLoading = false;
    notifyListeners();
    return success;
  }

  List<Transaction> get allTransactions {
    List<Transaction> txs = [];
    for (var item in itemList) {
      for (var tx in item.transactions) {
        txs.add(tx);
      }
    }
    txs.sort((a, b) => b.purchaseDate.compareTo(a.purchaseDate));
    return txs;
  }

  Future<void> addTransactionToItem({
    required int itemId,
    required double stocks,
    required double price,
  }) async {
    if (currentUser == null) return;
    final parentItem = itemList.firstWhereOrNull((i) => i.id == itemId);
    if (parentItem == null) {
      debugPrint("ParentItem es null para itemId: $itemId");
      return;
    }
    isLoading = true;
    notifyListeners();

    try {
      await _guarded(() async {
        final newTx = Transaction(
          stocks: stocks,
          purchasePrice: price,
          invEur: stocks * price,
          purchaseDate: DateTime.now(),
          isSynced: false,
        );
        await _transactionRepo.createTransaction(
          itemId,
          parentItem.serverId,
          newTx,
          currentUser!.token,
        );
        if (isOnline) {
          await _transactionRepo.syncAllPendings(currentUser!.token);
        }
        await fetchItems();
      });
    } catch (e) {
      debugPrint("Error al añadir transacción: $e");
      _onServerUnavailable();
      await fetchItems();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> initSettings() async {
    final savedTheme = await _settings.getTheme();
    final savedLang = await _settings.getLanguage();

    if (savedTheme == null) {
      _isDarkMode =
          PlatformDispatcher.instance.platformBrightness == Brightness.dark;
    } else {
      _isDarkMode = savedTheme;
    }

    if (savedLang == null) {
      String sysLang = PlatformDispatcher.instance.locale.languageCode;
      _currentLocale = (['es', 'gl', 'en'].contains(sysLang)) ? sysLang : 'es';
    } else {
      _currentLocale = savedLang;
    }
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    await _settings.saveTheme(_isDarkMode);
    notifyListeners();
  }

  Future<void> setLanguage(String code) async {
    _currentLocale = code;
    await _settings.saveLanguage(code);
    notifyListeners();
  }

  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  void _initConnectivityListener() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((
      results,
    ) {
      if (results.contains(ConnectivityResult.none)) {
        if (isOnline) connectionLostNotification = true;
        _onServerUnavailable();
        notifyListeners();
      } else {
        _checkRealConnection();
      }
    });
  }

  Future<pw.Document> generateGeneralReport() async {
    final pdf = pw.Document();
    final lang = _currentLocale;

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(
                level: 0,
                child: pw.Text(
                  "InvestTracking - ${AppStrings.get('total_res', lang)}",
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Text(
                "${AppStrings.get('total_val', lang)}: ${totalCurrentValue.toStringAsFixed(2)}",
              ),
              pw.Text(
                "${AppStrings.get('init_inv', lang)}: ${totalInvestment.toStringAsFixed(2)}",
              ),
              pw.Divider(),
              pw.Text(
                "${AppStrings.get('abs_pnl', lang)}: ${totalPnL.toStringAsFixed(2)}",
              ),
              pw.Text(
                "${AppStrings.get('perc_pnl', lang)}: ${totalPnLPercent.toStringAsFixed(2)}%",
              ),
              pw.SizedBox(height: 20),
              pw.Table.fromTextArray(
                context: context,
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                data: <List<String>>[
                  <String>['Activo', 'Inversión', 'Valor Actual'],
                  ...itemList.map(
                    (item) => [
                      item.name,
                      (item.totalInvEur.toStringAsFixed(2)),
                      (item.currentValue.toStringAsFixed(2)),
                    ],
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
    return pdf;
  }

  Future<bool> syncPendingData() async {
    if (currentUser == null) return false;
    bool success = true;
    try {
      await _itemRepo.syncPendingData(currentUser!.id, currentUser!.token);
    } on ServerUnavailableException {
      success = false;
    }
    await fetchItems();
    notifyListeners();
    return success;
  }

  double get totalCurrentValue =>
      itemList.fold(0, (sum, item) => sum + item.currentValue);

  double get totalInvestment =>
      itemList.fold(0, (sum, item) => sum + item.totalInvEur);

  double get totalPnL => totalCurrentValue - totalInvestment;

  double get totalPnLPercent =>
      totalInvestment == 0 ? 0 : (totalPnL / totalInvestment) * 100;
}
