import '../models/category.dart';
import '../service/api_service.dart';

class CategoryRepository {
  final ApiService _apiService = ApiService();

  Future<List<Category>> getAllCategories() async {
    try {
      final data = await _apiService.get('/categories');
      return (data as List).map((json) => Category.fromJson(json)).toList();
    } catch (e) {
      print("Error cargando categorías: $e");
      return [];
    }
  }
}
