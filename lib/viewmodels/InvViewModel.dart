import 'package:flutter/material.dart';
import 'package:http/http.dart' as _apiService;
import '../models/item.dart';
import '../models/user.dart';
import '../models/category.dart';
import '../repositories/item_repository.dart';
import '../repositories/auth_repository.dart';
import '../repositories/category_repository.dart';
import '../dao/user_dao.dart';

/// ViewModel principal que gestiona el estado de la interfaz de inversiones.
class InvViewModel extends ChangeNotifier {
  final ItemRepository _itemRepo = ItemRepository();
  final AuthRepository _authRepo = AuthRepository();
  final CategoryRepository _categoryRepo = CategoryRepository();
  final UserDao _userDao = UserDao();

  User? currentUser;
  List<Item> itemList = [];
  List<Category> categories = [];
  bool isLoading = false;
  bool isOnline = true;

  /// Autentica al usuario y prepara la sesión inicial.
  Future<bool> login(String username, String password) async {
    isLoading = true;
    notifyListeners();
    try {
      final result = await _authRepo.login(username, password);
      if (result != null) {
        currentUser = result;
        isOnline = true;
        await fetchItems(); // Carga inicial
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

  /// Verifica si hay una sesión activa guardada al arrancar la App.
  Future<bool> checkLocalSession() async {
    final savedUser = await _userDao.getUser();
    if (savedUser != null) {
      currentUser = savedUser;
      await fetchItems();
      return true;
    }
    return false;
  }

  /// Cierra la sesión y limpia las listas.
  Future<void> logout() async {
    await _userDao.deleteUser();
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

  /// MÉTODO PRINCIPAL DE CARGA: Sincroniza y refresca la lista.
  Future<void> fetchItems() async {
    if (currentUser == null) return;

    isLoading = true;
    notifyListeners();

    try {
      await _itemRepo.syncPendingData(currentUser!.id, currentUser!.token);

      itemList = await _itemRepo.fetchUserItems(
        currentUser!.id,
        currentUser!.token,
      );

      isOnline = true;
    } catch (e) {
      debugPrint("Modo Offline: Activando color rojo y cargando caché.");

      isOnline = false;

      itemList = await _itemRepo.getLocalItems(currentUser!.id);
    } finally {
      isLoading = false;
      notifyListeners();
    }
    for (var item in itemList) {
      debugPrint("--- ANALIZANDO: ${item.name} ---");
      debugPrint("Precio Actual: ${item.currentPrice}");
      debugPrint("Cantidad Total (Stocks): ${item.totalStocks}");
      debugPrint("Inversión Total: ${item.totalInvEur}");
      debugPrint("Valor Calculado: ${item.currentValue}");
      debugPrint("PnL Resultante: ${item.profitEur}");
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
      final newItem = Item(
        name: name,
        category: Category(id: categoryId, name: ""),
        transactions: [],
        currentPrice: price,
        isSynced: false,
      );

      await _itemRepo.saveItem(
        newItem,
        stocks,
        price,
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

  double get totalCurrentValue =>
      itemList.fold(0, (sum, item) => sum + item.currentValue);

  double get totalInvestment =>
      itemList.fold(0, (sum, item) => sum + item.totalInvEur);

  double get totalPnL => totalCurrentValue - totalInvestment;

  double get totalPnLPercent =>
      totalInvestment == 0 ? 0 : (totalPnL / totalInvestment) * 100;
}
