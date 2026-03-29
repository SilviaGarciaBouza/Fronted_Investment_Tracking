import '../dao/item_dao.dart';
import '../models/item.dart';
import '../service/api_service.dart';

/// Repositorio unificado para la gestión de activos financieros.
/// Coordina la persistencia híbrida: decide cuándo usar MariaDB (vía ApiService)
/// y cuándo usar SQLite (vía ItemDao).
class ItemRepository {
  final ApiService _apiService = ApiService();
  final ItemDao _itemDao = ItemDao();

  /// Recupera los activos del usuario.
  /// Primero intenta refrescar desde el servidor para actualizar precios e IDs,
  /// y luego devuelve siempre la verdad desde SQLite.
  Future<List<Item>> fetchUserItems(int userId, String token) async {
    try {
      final data = await _apiService.get('/items/user/$userId', token: token);
      final List<Item> remoteItems = (data as List)
          .map((j) => Item.fromJson(j))
          .toList();

      // Sincronización local: fusiona los datos del servidor con los locales.
      await _itemDao.saveItems(remoteItems, userId);
    } catch (e) {
      print(
        "Modo Offline: No se pudo conectar con el servidor para refrescar.",
      );
    }
    // Siempre devolvemos lo que hay en la base de datos local (caché).
    return await _itemDao.getItems(userId);
  }

  /// Guarda un item.
  /// Intenta el guardado remoto. Si tiene éxito, actualiza el ID local con el de MariaDB.
  /// Si falla la red, lo guarda en SQLite marcándolo como pendiente de sincronizar.
  Future<void> saveItem(
    Item item,
    double stocks,
    double price,
    int userId,
    String token,
  ) async {
    try {
      final response = await _apiService.post('/items', {
        "name": item.name,
        "userId": userId,
        "categoryId": item.category.id,
        "initialStocks": stocks,
        "initialPrice": price,
      }, token: token);

      if (response != null) {
        // El servidor nos da el ID oficial; actualizamos SQLite de forma atómica.
        final serverItem = Item.fromJson(response);
        await _itemDao.saveItems([serverItem], userId);
      } else {
        throw Exception("Respuesta nula del servidor");
      }
    } catch (e) {
      // Sin conexión: guardado local con flag is_synced = 0.
      print("Guardando localmente por falta de conexión");
      await _itemDao.saveItemOffline(item, stocks, price, userId);
    }
  }

  /// Elimina un activo del servidor MariaDB.
  /// Retorna [true] si el servidor confirma el borrado, permitiendo al
  /// DAO eliminar el registro físico en SQLite.
  Future<bool> deleteRemoteItem(int serverId, String token) async {
    try {
      return await _apiService.delete('/items/$serverId', token: token);
    } catch (e) {
      print("Error eliminando en el servidor: $e");
      return false;
    }
  }

  /// Procesa la cola de activos pendientes de sincronización.
  /// Recorre los items creados offline y los promociona a MariaDB.
  Future<void> syncPendingData(int userId, String token) async {
    final List<Item> pendingItems = await _itemDao.getUnsyncedItems(userId);

    if (pendingItems.isEmpty) return;

    for (var localItem in pendingItems) {
      try {
        final response = await _apiService.post('/items', {
          "name": localItem.name,
          "userId": userId,
          "categoryId": localItem.category.id,
          "initialStocks": localItem.totalStocks,
          "initialPrice": localItem.transactions.isNotEmpty
              ? localItem.transactions.first.purchasePrice
              : 0.0,
        }, token: token);

        if (response != null) {
          final serverItem = Item.fromJson(response);
          // Migración atómica de ID local a ID real del servidor.
          await _itemDao.saveItems([serverItem], userId);
        }
      } catch (e) {
        print("Fallo en sincronización de ${localItem.name}: $e");
      }
    }
  }

  Future<bool> deleteItem(int localId, int? serverId, String token) async {
    try {
      if (serverId != null) {
        final success = await _apiService.delete(
          '/items/$serverId',
          token: token,
        );

        if (success) {
          await _itemDao.deleteItemPhysically(localId);
          return true;
        }
      } else {
        await _itemDao.deleteItemPhysically(localId);
        return true;
      }
      return false;
    } catch (e) {
      print("Error en red, aplicando borrado lógico: $e");
      await _itemDao.markForDeletion(localId);
      return false;
    }
  }
}
