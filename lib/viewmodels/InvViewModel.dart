import 'package:flutter/material.dart';
import 'package:investment_tracking/dao/item_dao.dart'; // /AA - Importante para acceso directo a SQLite
import 'package:investment_tracking/dao/user_dao.dart';
import '../models/item.dart';
import '../models/user.dart';
import '../models/category.dart';
import '../repositories/item_repository.dart';
import '../repositories/auth_repository.dart';
import '../repositories/category_repository.dart';

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

  Future<bool> login(String username, String password) async {
    isLoading = true;
    notifyListeners();
    try {
      final result = await _authRepo.login(username, password);
      if (result != null) {
        currentUser = result;
        await _userDao.saveUser(currentUser!);
        await Future.wait([fetchCategories(), fetchItems()]);
        return true;
      }
      return false;
    } catch (e) {
      debugPrint("Error login: El servidor no responde.");
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> checkLocalSession() async {
    final savedUser = await _userDao.getUser();
    if (savedUser != null && savedUser.token.isNotEmpty) {
      currentUser = savedUser;
      await Future.wait([fetchCategories(), fetchItems()]);
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<void> _syncUnsyncedItems() async {
    if (currentUser == null) return;

    final unsynced = await _itemDao.getUnsyncedItems(currentUser!.id);

    if (unsynced.isEmpty) return;

    debugPrint("Sincronizando ${unsynced.length} ítems pendientes...");

    for (var item in unsynced) {
      final Map<String, dynamic> data = {
        "name": item.name,
        "userId": currentUser!.id,
        "categoryId": item.category.id != 0 ? item.category.id : 1,
        "initialStocks": item.stocks,
        "initialPrice": item.currentPrice,
      };

      try {
        if (await _itemRepo.saveItem(data, currentUser!.token)) {
          await _itemDao.markAsSynced(item.id);
          debugPrint("Ítem ${item.name} sincronizado correctamente.");
        }
      } catch (e) {
        debugPrint("Fallo en sincronización de ${item.name}: Sigue en cola.");
        break;
      }
    }
  }

  Future<void> fetchCategories() async {
    if (currentUser == null) return;

    try {
      categories = await _categoryRepo.getAllCategories(currentUser!.token);
      debugPrint("Categorías cargadas con éxito: ${categories.length}");
    } catch (e) {
      debugPrint("Error cargando categorías: $e");
    }
    notifyListeners();
  }

  /*
  Future<void> fetchItems() async {
    if (currentUser == null) return;

    await _syncUnsyncedItems();

    try {
      itemList = await _itemRepo.fetchUserItems(
        currentUser!.id,
        currentUser!.token,
      );
    } catch (e) {
      itemList = await _itemDao.getItems(currentUser!.id);
      debugPrint("Modo Offline: Datos cargados desde SQLite.");
    } finally {
      notifyListeners();
    }
  }
*/
  Future<void> saveNewItem({
    required String name,
    required double stocks,
    required double price,
    required int categoryId,
  }) async {
    if (currentUser == null) return;
    isLoading = true;
    notifyListeners();

    final Map<String, dynamic> data = {
      "name": name,
      "userId": currentUser!.id,
      "categoryId": categoryId,
      "initialStocks": stocks,
      "initialPrice": price,
    };

    try {
      if (await _itemRepo.saveItem(data, currentUser!.token)) {
        await Future.delayed(const Duration(milliseconds: 500));
        await fetchItems();
      }
    } catch (e) {
      debugPrint("Servidor inaccesible. Guardando inversión localmente...");

      final tempItem = Item(
        id: DateTime.now().millisecondsSinceEpoch,
        name: name,
        category: Category(id: categoryId, name: ""),
        transactions: [],
        currentPrice: price,
      );

      await _itemDao.saveItemOffline(tempItem, currentUser!.id);

      itemList = await _itemDao.getItems(currentUser!.id);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteItem(int itemId) async {
    if (currentUser == null) return;
    isLoading = true;
    notifyListeners();

    try {
      bool success = await _itemRepo.deleteItem(itemId, currentUser!.token);

      if (success) {
        itemList.removeWhere((item) => item.id == itemId);
        debugPrint("Borrado confirmado por el servidor.");
      } else {
        throw Exception("Servidor rechazó el borrado");
      }
    } catch (e) {
      await _itemDao.deleteItem(itemId);
      itemList.removeWhere((item) => item.id == itemId);
      debugPrint("Borrado local realizado.");
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  double get totalCurrentValue =>
      itemList.fold(0, (sum, item) => sum + item.valueEur);
  double get totalInvestment =>
      itemList.fold(0, (sum, item) => sum + item.invEur);
  double get totalPnL => totalCurrentValue - totalInvestment;
  double get totalPnLPercent =>
      totalInvestment == 0 ? 0 : (totalPnL / totalInvestment) * 100;

  bool isOnline = true;

  Future<void> fetchItems() async {
    if (currentUser == null) return;

    await _syncUnsyncedItems();

    try {
      itemList = await _itemRepo.fetchUserItems(
        currentUser!.id,
        currentUser!.token,
      );
      isOnline = true;
    } catch (e) {
      itemList = await _itemDao.getItems(currentUser!.id);
      isOnline = false;
      debugPrint("Modo Offline activo.");
    } finally {
      notifyListeners();
    }
  }
}
