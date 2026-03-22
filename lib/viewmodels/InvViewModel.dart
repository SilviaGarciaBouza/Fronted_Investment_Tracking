import 'package:flutter/material.dart';
import 'package:investment_tracking/dao/item_dao.dart';
import 'package:investment_tracking/dao/user_dao.dart';
import '../models/item.dart';
import '../models/user.dart';
import '../models/category.dart';
import '../repositories/item_repository.dart';
import '../repositories/auth_repository.dart';
import '../repositories/category_repository.dart';

/// ViewModel principal que gestiona el estado de la interfaz de inversiones.
///
/// Implementa la lógica de sincronización offline-online y notifica a la UI
/// los cambios en los datos del usuario y sus activos.
class Invviewmodel extends ChangeNotifier {
  final ItemRepository _itemRepo = ItemRepository();
  final AuthRepository _authRepo = AuthRepository();
  final CategoryRepository _categoryRepo = CategoryRepository();
  final UserDao _userDao = UserDao();
  final ItemDao _itemDao = ItemDao();

  User? currentUser;
  List<Item> itemList = [];
  List<Category> categories = [];
  bool isLoading = false;
  bool isOnline = true;

  /// Autentica al usuario y carga sus datos iniciales.
  Future<bool> login(String username, String password) async {
    debugPrint("llegue a login");

    isLoading = true;
    notifyListeners();
    try {
      final result = await _authRepo.login(username, password);
      if (result != null) {
        debugPrint("llegue a login, result es distnto a null");
        currentUser = result;
        await _userDao.saveUser(currentUser!);
        isOnline = true;
        await fetchCategories();
        await fetchItems();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint("Error login: El servidor no responde.");
      print("llegue a login, result es  null");
      isOnline = false;
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Verifica si existe una sesión guardada localmente en SQLite.
  Future<bool> checkLocalSession() async {
    debugPrint("llegue a checkLocalSession");
    final savedUser = await _userDao.getUser();
    if (savedUser != null && savedUser.token.isNotEmpty) {
      currentUser = savedUser;
      isOnline = true;
      await fetchCategories();
      await fetchItems();
      return true;
    }
    return false;
  }

  bool lastSyncSuccess = true;

  Future<void> fetchItems() async {
    if (currentUser == null) return;

    try {
      final remoteItems = await _itemRepo.fetchUserItems(
        currentUser!.id,
        currentUser!.token,
      );

      itemList = remoteItems;
      isOnline = true;
      lastSyncSuccess = true;

      _runBackgroundSync();
    } catch (e) {
      debugPrint("Error fetchItems: Tirando de base de datos local.");
      itemList = await _itemDao.getItems(currentUser!.id);
      isOnline = false;
      lastSyncSuccess = false;
    } finally {
      notifyListeners();
    }
  }

  Future<void> _runBackgroundSync() async {
    await syncEverything();
    // Si algo cambió tras sincronizar, refrescamos la lista local
    itemList = await _itemDao.getItems(currentUser!.id);
    notifyListeners();
  }

  /// Sincroniza las altas y bajas con el servidor.
  /// Retorna [true] si se sincronizó todo con éxito, [false] si algo falló.
  Future<bool> syncEverything() async {
    if (currentUser == null) return false;
    bool allGood = true;

    // Sincronización de borrados
    final pendingDeletes = await _itemDao.getPendingDeletions();
    for (var p in pendingDeletes) {
      try {
        if (await _itemRepo.deleteRemoteItem(
          p['server_id'],
          currentUser!.token,
        )) {
          await _itemDao.deleteItem(p['id']);
        } else {
          allGood = false; // El servidor respondió pero no pudo borrar
        }
      } catch (e) {
        allGood = false; // Error de red
        break;
      }
    }

    // Sincronización de altas
    final unsynced = await _itemDao.getUnsyncedItems(currentUser!.id);
    for (var item in unsynced) {
      final Map<String, dynamic> data = {
        "name": item.name,
        "userId": currentUser!.id,
        "categoryId": item.category.id != 0 ? item.category.id : 1,
        "initialStocks": item.stocks,
        "initialPrice": item.currentPrice,
      };

      print("Item: ${item.name}");
      print("Stocks: ${item.stocks}");
      print("Precio Actual: ${item.currentPrice}");

      try {
        if (await _itemRepo.saveItem(data, currentUser!.token)) {
          await _itemDao.markAsSynced(item.id);
        } else {
          allGood = false;
        }
      } catch (e) {
        allGood = false;
        break;
      }
    }
    return allGood;
  }

  /// Guarda una nueva inversión localmente y, si hay red, la sube al servidor.
  Future<String> saveNewItem({
    required String name,
    required double stocks,
    required double price,
    required int categoryId,
  }) async {
    if (currentUser == null) return "Error: No hay sesión";
    isLoading = true;
    notifyListeners();

    final int tempId = DateTime.now().millisecondsSinceEpoch;
    final tempItem = Item(
      id: tempId,
      name: name,
      category: Category(id: categoryId, name: ""),
      transactions: [],
      currentPrice: price,
      isSynced: false,
    );

    await _itemDao.saveItemOffline(tempItem, stocks, price, currentUser!.id);

    itemList = await _itemDao.getItems(currentUser!.id);
    notifyListeners();

    try {
      final Map<String, dynamic> data = {
        "name": name,
        "userId": currentUser!.id,
        "categoryId": categoryId,
        "initialStocks": stocks,
        "initialPrice": price,
      };

      if (isOnline && await _itemRepo.saveItem(data, currentUser!.token)) {
        await Future.delayed(const Duration(milliseconds: 500));
        await fetchItems();
        return "Inversión sincronizada ✅";
      }
      return "Guardado localmente (Sin conexión) ☁️";
    } catch (e) {
      isOnline = false;
      return "Guardado en modo offline ☁️";
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Elimina una inversión gestionando si el borrado es local o debe ser remoto.
  Future<String> deleteItem(int localId) async {
    isLoading = true;
    notifyListeners();

    try {
      final item = itemList.firstWhere((i) => i.id == localId);

      if (item.serverId != null) {
        if (isOnline) {
          bool success = await _itemRepo.deleteRemoteItem(
            item.serverId!,
            currentUser!.token,
          );
          if (success) {
            await _itemDao.deleteItem(localId);
            itemList.removeWhere((i) => i.id == localId);
            return "Eliminado del servidor con éxito";
          }
        }
        await _itemDao.markForDeletion(localId);
        itemList.removeWhere((i) => i.id == localId);
        return "Marcado para borrar (Se sincronizará al volver la red)";
      } else {
        await _itemDao.deleteItem(localId);
        itemList.removeWhere((i) => i.id == localId);
        return "Inversión local eliminada";
      }
    } catch (e) {
      return "Error al procesar el borrado";
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Carga el catálogo de categorías desde el servidor o caché.
  Future<void> fetchCategories() async {
    if (currentUser == null) return;
    try {
      categories = await _categoryRepo.getAllCategories(currentUser!.token);
    } catch (e) {
      debugPrint("Error cargando categorías: Usando caché local.");
    }
    notifyListeners();
  }

  /// Realiza el cierre de sesión completo.
  ///
  /// Borra los datos de SQLite y reinicia las listas del ViewModel para que
  /// la interfaz se actualice inmediatamente.
  Future<void> logout() async {
    await _userDao.deleteUser();

    currentUser = null;
    itemList = [];
    categories = [];
    isOnline = false;

    notifyListeners();
  }

  /// Calcula el valor total actual de toda la cartera en euros.
  double get totalCurrentValue =>
      itemList.fold(0, (sum, item) => sum + item.valueEur);

  /// Calcula el total de capital invertido originalmente.
  double get totalInvestment =>
      itemList.fold(0, (sum, item) => sum + item.invEur);

  /// Calcula el beneficio o pérdida total en euros.
  double get totalPnL => totalCurrentValue - totalInvestment;

  /// Calcula el porcentaje de rentabilidad total de la cartera.
  double get totalPnLPercent =>
      totalInvestment == 0 ? 0 : (totalPnL / totalInvestment) * 100;
}
