import 'package:flutter/material.dart';
import 'package:investment_tracking/dao/user_dao.dart';
import '../models/item.dart';
import '../models/user.dart';
import '../models/category.dart';
import '../repositories/item_repository.dart';
import '../repositories/auth_repository.dart';
import '../repositories/category_repository.dart';

/// Gestiona el estado de la aplicación y la lógica de negocio para la UI.
class Invviewmodel extends ChangeNotifier {
  final ItemRepository _itemRepo = ItemRepository();
  final AuthRepository _authRepo = AuthRepository();
  final CategoryRepository _categoryRepo = CategoryRepository();

  final UserDao _userDao = UserDao();
  User? currentUser;
  List<Item> itemList = [];
  List<Category> categories = [];
  bool isLoading = false;

  /// Realiza el login enviando usuario y contraseña.
  Future<bool> login(String username, String password) async {
    isLoading = true;
    notifyListeners();
    try {
      final result = await _authRepo.login(username, password);
      print(result);
      print(result.runtimeType);

      if (result is User) {
        currentUser = result;

        await _userDao.saveUser(currentUser!);

        await Future.wait([fetchCategories(), fetchItems()]);
        return true;
      }

      return false;
    } catch (e) {
      debugPrint("Error crítico en el proceso de login: $e");
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Recupera la lista de categorías (con soporte offline vía repositorio).
  Future<void> fetchCategories() async {
    try {
      categories = await _categoryRepo.getAllCategories();
    } catch (e) {
      debugPrint("Aviso: Usando categorías locales o lista vacía.");
    }
    notifyListeners();
  }

  /// Obtiene los activos financieros (con soporte offline vía repositorio).
  Future<void> fetchItems() async {
    if (currentUser == null) return;
    try {
      itemList = await _itemRepo.fetchUserItems(currentUser!.id);
    } catch (e) {
      debugPrint("No se pudo conectar al servidor, mostrando datos locales.");
    } finally {
      notifyListeners();
    }
  }

  /// Registra una nueva inversión y refresca la lista.
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
      if (await _itemRepo.saveItem(data)) {
        await Future.delayed(const Duration(milliseconds: 2500));
        await fetchItems();
      }
    } catch (e) {
      debugPrint("Error al guardar: $e");
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Elimina una inversión y actualiza la lista local.
  Future<void> deleteItem(int itemId) async {
    isLoading = true;
    notifyListeners();

    try {
      if (await _itemRepo.deleteItem(itemId)) {
        itemList.removeWhere((item) => item.id == itemId);
      }
    } catch (e) {
      debugPrint("Error al eliminar: $e");
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Verifica si hay un usuario guardado localmente (Auto-login)
  Future<bool> checkLocalSession() async {
    try {
      final savedUser = await _userDao.getUser();
      if (savedUser != null) {
        currentUser = savedUser;

        await Future.wait([fetchCategories(), fetchItems()]);

        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint("Error recuperando sesión local: $e");
    }
    return false;
  }

  /// Valor actual total
  double get totalCurrentValue =>
      itemList.fold(0, (sum, item) => sum + item.valueEur);

  /// Inversión total
  double get totalInvestment =>
      itemList.fold(0, (sum, item) => sum + item.invEur);

  /// Beneficio/Pérdida neto
  double get totalPnL => totalCurrentValue - totalInvestment;

  /// Porcentaje total
  double get totalPnLPercent =>
      totalInvestment == 0 ? 0 : (totalPnL / totalInvestment) * 100;
}
