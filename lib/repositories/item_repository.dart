import 'package:investment_tracking/models/item.dart';
import 'package:investment_tracking/service/api_service.dart';

class ItemRepository {
  final ApiService _apiService = ApiService();

  Future<List<Item>> fetchUserItems(int userId) async {
    try {
      final data = await _apiService.get('/items/user/$userId');
      return (data as List).map((json) => Item.fromJson(json)).toList();
    } catch (e) {
      print("Error buscando items: $e");
      //return [];
      throw e;
    }
  }

  Future<bool> saveItem(Map<String, dynamic> itemData) async {
    try {
      await _apiService.post('/items', itemData);
      return true;
    } catch (e) {
      print("Error guardando item: $e");
      return false;
    }
  }

  Future<bool> deleteItem(int itemId) async {
    try {
      return await _apiService.delete('/items/$itemId');
    } catch (e) {
      print("Error eliminando item: $e");
      return false;
    }
  }
}
