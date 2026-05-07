import 'dart:ui';
import 'dart:async';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:investment_tracking/models/transaction.dart';
import 'package:investment_tracking/repositories/TransactionRepository.dart';
import 'package:investment_tracking/repositories/session_repository.dart';
import 'package:investment_tracking/service/SettingsService.dart';
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
  InvViewModel() {
    _initConnectivityListener();
    _startHeartbeat();
  }
  void _startHeartbeat() {
    // Cada 10 segundos preguntams al servidor
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _checkRealConnection();
    });
  }

  /// Verifica la conexión real con el servidor y gestiona la resincronización.
  // En InvViewModel
  Future<void> _checkRealConnection() async {
    try {
      // Solo preguntamos si el servidor está vivo para cambiar el color del icono
      final bool hasServer = await _authRepo.checkConnection().timeout(
        const Duration(seconds: 2),
      );

      if (isOnline != hasServer) {
        isOnline = hasServer;
        notifyListeners(); // Esto solo cambia el icono de la nube
      }
    } catch (_) {
      if (isOnline) {
        isOnline = false;
        notifyListeners();
      }
    }
  }

  Future<bool> loadUserSession() async {
    final userId = await _sessionRepo.getUserId();
    currentUser = await _authRepo.loadUser();
    await fetchItems();
    return userId != null;
  }

  /// Autentica al usuario y prepara la sesión inicial.
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
      final success = await _transactionRepo.deleteTransaction(
        localId,
        serverId,
        currentUser!.token,
      );

      await fetchItems();

      debugPrint(
        success ? "Eliminado con éxito" : "Marcado para borrar offline",
      );
    } catch (e) {
      debugPrint("Error al borrar transacción: $e");
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  ///addTransaction

  //______________________--
  /// Verifica si hay una sesión activa guardada al arrancar la App.
  /* Future<bool> checkLocalSession() async {
    final savedUser = await _userDao.getUser();
    if (savedUser != null) {
      currentUser = savedUser;
      await fetchItems();
      return true;
    }
    return false;
  }*/
  Future<bool> checkLocalSession() async {
    try {
      final response = await _authRepo.checkConnection().timeout(
        const Duration(seconds: 2),
        onTimeout: () => true,
      );
      isOnline = response;
    } catch (_) {
      isOnline = true;
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
      categories = await _categoryRepo.getAllCategories(currentUser!.token);
      itemList = await _itemRepo.fetchUserItems(
        currentUser!.id,
        currentUser!.token,
      );
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
    if (currentUser == null) return "Error: Sin sesión";

    isLoading = true;
    notifyListeners();

    try {
      await _itemRepo.saveTransaction(
        name,
        stocks,
        price,
        categoryId,
        currentUser!.id,
        currentUser!.token,
      );
      await fetchItems();

      return isOnline
          ? "Inversión guardada "
          : "Guardado localmente (Sin conexión) ";
    } catch (e) {
      return "Error al guardar: $e";
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<String> deleteItem(int localId, int? serverId) async {
    if (currentUser == null) return "Error: Sin sesión";
    isLoading = true;
    notifyListeners();

    final success = await _itemRepo.deleteItem(
      localId,
      serverId,
      currentUser!.token,
    );

    await fetchItems();

    return success ? "Eliminado" : "Marcado para borrar (Offline)";
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
      // 1. Creamos el objeto Transaction
      final newTx = Transaction(
        stocks: stocks,
        purchasePrice: price,
        invEur: stocks * price,
        purchaseDate: DateTime.now(),
        isSynced: false, // Por defecto false, el repo decidirá
      );
      // 2. LLAMAR AL REPOSITORIO (Esto es lo que faltaba)
      // El repo intentará MariaDB, si falla, lo dejará en SQLite (is_synced = 0)
      await _transactionRepo.createTransaction(
        itemId,
        parentItem.serverId,
        newTx,
        currentUser!.token,
      );
      if (isOnline) {
        await _transactionRepo.syncAllPendings(currentUser!.token);
      }

      // 3. Refrescar la lista
      await fetchItems();
    } catch (e) {
      debugPrint("Error al añadir transacción: $e");
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

  void toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    await _settings.saveTheme(_isDarkMode);
    notifyListeners();
  }

  void setLanguage(String code) async {
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
        isOnline = false;
        notifyListeners();
      } else {
        _checkRealConnection();
      }
    });
  }

  Future<void> syncPendingData() async {
    if (currentUser == null) return;
    await _itemRepo.syncPendingData(currentUser!.id, currentUser!.token);
    await fetchItems();
    notifyListeners();
  }

  double get totalCurrentValue =>
      itemList.fold(0, (sum, item) => sum + item.currentValue);

  double get totalInvestment =>
      itemList.fold(0, (sum, item) => sum + item.totalInvEur);

  double get totalPnL => totalCurrentValue - totalInvestment;

  double get totalPnLPercent =>
      totalInvestment == 0 ? 0 : (totalPnL / totalInvestment) * 100;
}
