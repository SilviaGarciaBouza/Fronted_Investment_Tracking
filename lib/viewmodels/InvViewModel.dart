import 'package:flutter/material.dart';
import '../models/item.dart';
import '../models/user.dart';
import '../models/category.dart';
import '../repositories/item_repository.dart';
import '../repositories/auth_repository.dart';
import '../repositories/category_repository.dart';

/// Gestiona el estado de la aplicacion y la logica de negocio para la UI.
class Invviewmodel extends ChangeNotifier {
  final ItemRepository _itemRepo = ItemRepository();
  final AuthRepository _authRepo = AuthRepository();
  final CategoryRepository _categoryRepo = CategoryRepository();

  User? currentUser;
  List<Item> itemList = [];
  List<Category> categories = [];
  bool isLoading = false;

  /// Realiza el login enviando usuario y contraseña.
  /// Si tiene éxito, carga automáticamente los datos iniciales.
  Future<bool> login(String username, String password) async {
    isLoading = true;
    notifyListeners();
    try {
      // Ahora pasamos ambos parametros al repositorio corregido
      currentUser = await _authRepo.login(username, password);
      if (currentUser != null) {
        await fetchCategories();
        await fetchItems();
        return true;
      }
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Recupera la lista de categorias disponibles desde el servidor.
  Future<void> fetchCategories() async {
    categories = await _categoryRepo.getAllCategories();
    notifyListeners();
  }

  /// Obtiene los activos financieros asociados al usuario actual.
  Future<void> fetchItems() async {
    if (currentUser == null) return;
    try {
      itemList = await _itemRepo.fetchUserItems(currentUser!.id);
    } catch (e) {
      print("No se pudo actualizar, manteniendo datos previos.");
    } finally {
      notifyListeners();
    }
  }

  /// Registra una nueva inversion y refresca la lista principal.
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
    if (await _itemRepo.saveItem(data)) {
      await Future.delayed(const Duration(seconds: 1));
      await fetchItems();
    }

    isLoading = false;
    notifyListeners();
  }

  /// Elimina una inversión del backend y actualiza la lista local.
  Future<void> deleteItem(int itemId) async {
    isLoading = true;
    notifyListeners();

    if (await _itemRepo.deleteItem(itemId)) {
      // Si el backend confirmó el borrado, lo quitamos de nuestra lista en memoria
      itemList.removeWhere((item) => item.id == itemId);
    }

    isLoading = false;
    notifyListeners();
  }

  /// Calcula el valor actual total de la cartera: $$\sum (stocks \times price)$$
  double get totalCurrentValue =>
      itemList.fold(0, (sum, item) => sum + item.valueEur);

  /// Calcula la inversion total realizada: $$\sum (invEur)$$
  double get totalInvestment =>
      itemList.fold(0, (sum, item) => sum + item.invEur);

  /// Diferencia entre valor actual e inversion: $$PnL = Value - Investment$$
  double get totalPnL => totalCurrentValue - totalInvestment;

  /// Porcentaje de beneficio o perdida total.
  double get totalPnLPercent =>
      totalInvestment == 0 ? 0 : (totalPnL / totalInvestment) * 100;
}
