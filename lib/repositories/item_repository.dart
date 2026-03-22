import 'package:investment_tracking/dao/item_dao.dart';
import 'package:investment_tracking/models/item.dart';
import 'package:investment_tracking/service/api_service.dart';

/// Repositorio central para la gestión de activos financieros (Items).
///
/// Coordina la obtención de datos remotos y la persistencia local para soporte offline.
class ItemRepository {
  final ApiService _apiService = ApiService();
  final ItemDao _itemDao = ItemDao();

  /// Recupera todas las inversiones de un usuario específico.
  ///
  /// Limpia los items sincronizados antiguos para evitar duplicados y guarda los nuevos.
  Future<List<Item>> fetchUserItems(int userId, String token) async {
    try {
      final data = await _apiService.get('/items/user/$userId', token: token);

      final List<Item> items = (data as List)
          .map((json) => Item.fromJson(json))
          .toList();

      await _itemDao.deleteSyncedItems();
      await _itemDao.saveItems(items, userId);

      return await _itemDao.getItems(userId);
    } catch (e) {
      return await _itemDao.getItems(userId);
    }
  }

  /// Envía un nuevo activo al servidor MariaDB.
  Future<bool> saveItem(Map<String, dynamic> itemData, String token) async {
    try {
      final response = await _apiService.post('/items', itemData, token: token);
      return response != null;
    } catch (e) {
      print("Error enviando al servidor: $e");
      return false;
    }
  }

  /// Elimina una inversión del servidor de forma permanente.
  Future<bool> deleteRemoteItem(int serverId, String token) async {
    try {
      return await _apiService.delete('/items/$serverId', token: token);
    } catch (e) {
      print("Error eliminando en servidor: $e");
      return false;
    }
  }
}
