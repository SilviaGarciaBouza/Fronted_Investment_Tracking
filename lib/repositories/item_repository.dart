import 'package:flutter/foundation.dart';

import '../dao/item_dao.dart';
import '../models/item.dart';
import '../service/api_service.dart';

/// Repositorio unificado para la gestión de activos financieros.
/// Coordina la persistencia híbrida: decide cuándo usar MariaDB (vía ApiService)
/// y cuándo usar SQLite (vía ItemDao).
class ItemRepository {
  final ApiService _apiService = ApiService();
  final ItemDao _itemDao = ItemDao();

  Future<List<Item>> fetchUserItems(int userId, String token) async {
    try {
      final data = await _apiService.get('/items/user/$userId', token: token);
      final List<Item> remoteItems = (data as List)
          .map((j) => Item.fromJson(j))
          .toList();
      await _itemDao.saveItems(remoteItems, userId);

      return await _itemDao.getItems(userId);
    } catch (e) {
      debugPrint("Modo Offline: No se pudo refrescar desde el servidor.");
      rethrow;
    }
  }

  Future<List<Item>> getLocalItems(int userId) async {
    return await _itemDao.getItems(userId);
  }

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
        final serverItem = Item.fromJson(response);
        await _itemDao.saveItems([serverItem], userId);
      }
    } catch (e) {
      await _itemDao.saveItemOffline(item, stocks, price, userId);
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
      await _itemDao.markForDeletion(localId);
      return false;
    }
  }

  Future<void> syncPendingData(int userId, String token) async {
    final List<Item> pendingItems = await _itemDao.getUnsyncedItems(userId);
    for (var localItem in pendingItems) {
      try {
        final response = await _apiService.post('/items', {
          "name": localItem.name,
          "userId": userId,
          "categoryId": localItem.category.id,
          "initialStocks": localItem.totalStocks,
          "initialPrice": localItem.transactions.first.purchasePrice,
        }, token: token);

        if (response != null) {
          final serverItem = Item.fromJson(response);
          await _itemDao.saveItems([serverItem], userId);
        }
      } catch (e) {}
    }

    final List<Item> itemsToDelete = await _itemDao.getPendingDeletions(userId);
    for (var item in itemsToDelete) {
      try {
        if (item.serverId != null) {
          final success = await _apiService.delete(
            '/items/${item.serverId}',
            token: token,
          );
          if (success) await _itemDao.deleteItemPhysically(item.id!);
        } else {
          await _itemDao.deleteItemPhysically(item.id!);
        }
      } catch (e) {}
    }
  }
}
