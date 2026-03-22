import 'package:investment_tracking/dao/caegory_dao.dart';
import '../models/category.dart';
import '../service/api_service.dart';

/// Repositorio para la gestión de categorías de inversión.
///
/// Implementa una estrategia de caché: intenta descargar de la red y, si falla,
/// recurre a los datos almacenados en SQLite.
class CategoryRepository {
  final ApiService _apiService = ApiService();
  final CategoryDao _categoryDao = CategoryDao();

  /// Obtiene el listado de categorías disponibles.
  ///
  /// Si hay conexión, actualiza la base de datos local con los datos del servidor.
  Future<List<Category>> getAllCategories(String? token) async {
    try {
      final data = await _apiService.get('/categories', token: token);

      final List<Category> categories = (data as List)
          .map((json) => Category.fromJson(json))
          .toList();

      await _categoryDao.saveCategories(categories);
      return categories;
    } catch (e) {
      print("Categorías desde SQLite (Offline): $e");
      return await _categoryDao.getCategories();
    }
  }
}
