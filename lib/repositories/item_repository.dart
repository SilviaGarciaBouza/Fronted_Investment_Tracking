import 'package:investment_tracking/dao/item_dao.dart';
import 'package:investment_tracking/database/database_helper.dart';
import 'package:investment_tracking/models/item.dart';
import 'package:investment_tracking/service/api_service.dart';

class ItemRepository {
  final ApiService _apiService = ApiService();
  final ItemDao _itemDao = ItemDao();
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<List<Item>> fetchUserItems(int userId, String token) async {
    try {
      final data = await _apiService.get('/items/user/$userId', token: token);
      final List<Item> items = (data as List)
          .map((json) => Item.fromJson(json))
          .toList();

      await _itemDao.deleteAllItems();
      await _itemDao.saveItems(items, userId);

      return items;
    } catch (e) {
      print("Modo Offline: Reconstruyendo cartera desde SQLite...");

      // OFFLINE
      final db = await _dbHelper.database;

      final List<Map<String, dynamic>> itemMaps = await db.query(
        'items',
        where: 'user_id = ?',
        whereArgs: [userId],
      );
      List<Item> itemsOffline = [];
      print("DEBUG: Entrando en modo offline por error: $e");

      print("DEBUG: Items encontrados en SQLite: ${itemMaps.length}");
      for (var map in itemMaps) {
        final List<Map<String, dynamic>> txMaps = await db.query(
          'transactions',
          where: 'item_id = ?',
          whereArgs: [map['id']],
        );

        itemsOffline.add(Item.fromLocalMap(map, txMaps));
      }

      return itemsOffline;
    }
  }

  Future<bool> saveItem(Map<String, dynamic> itemData, String token) async {
    try {
      await _apiService.post('/items', itemData, token: token);
      return true;
    } catch (e) {
      print("Error guardando item: $e");
      return false;
    }
  }

  Future<bool> deleteItem(int itemId, String token) async {
    try {
      final success = await _apiService.delete('/items/$itemId', token: token);

      if (success) {
        await _itemDao.deleteItem(itemId);
      }
      return success;
    } catch (e) {
      print("Error eliminando ítem en repositorio: $e");
      return false;
    }
  }
}
