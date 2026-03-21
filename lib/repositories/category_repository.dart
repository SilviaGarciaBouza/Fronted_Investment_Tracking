import 'package:investment_tracking/dao/caegory_dao.dart';

import '../models/category.dart';
import '../service/api_service.dart';

class CategoryRepository {
  final ApiService _apiService = ApiService();
  final CategoryDao _categoryDao = CategoryDao();
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
