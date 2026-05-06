import 'package:flutter/foundation.dart' hide Category;
import 'package:investment_tracking/dao/caegory_dao.dart';
import 'package:investment_tracking/dao/transaction_dao.dart';
import 'package:investment_tracking/models/transaction.dart';
import '../models/category.dart';
import '../dao/item_dao.dart';
import '../models/item.dart';
import '../service/api_service.dart';

/// Repositorio unificado para la gestión de activos financieros.
/// Coordina la persistencia híbrida: decide cuándo usar MariaDB (vía ApiService)
/// y cuándo usar SQLite (vía ItemDao).
class ItemRepository {
  final ApiService _apiService = ApiService();
  final ItemDao _itemDao = ItemDao();
  final CategoryDao _categoryDao = CategoryDao();
  final TransactionDao _transactionDao = TransactionDao();

  ///Obtiene los datos del servidor, los guarda en local y devuelve los datos de local
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
      return await getLocalItems(userId);
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

  Future<bool> deleteTransaction(
    int localId,
    int? serverId,
    String token,
    int itemId,
  ) async {
    int numTransactionItemsTotal;
    int numTransactionItems;
    try {
      if (serverId != null) {
        final success = await _apiService.delete(
          '/transactions/$serverId',
          token: token,
        );

        if (success) {
          await _transactionDao.deletePhysically(localId);
          numTransactionItemsTotal = await _transactionDao
              .getTransactionItemsCountTotal(itemId);

          if (numTransactionItemsTotal == 0) {
            _itemDao.deleteItemPhysically(itemId);
          }
          return true;
        } else {
          await _transactionDao.markForDeletion(localId);
          numTransactionItems = await _transactionDao.getTransactionItemsCount(
            itemId,
          );
          if (numTransactionItems == 0) {
            _itemDao.markForDeletion(itemId);
          }
          return true;
        }
      } else {
        await _transactionDao.markForDeletion(localId);
        numTransactionItems = await _transactionDao.getTransactionItemsCount(
          itemId,
        );
        if (numTransactionItems == 0) {
          _itemDao.markForDeletion(itemId);
        }
        return true;
      }
    } catch (e) {
      await _transactionDao.markForDeletion(localId);
      numTransactionItems = await _transactionDao.getTransactionItemsCount(
        itemId,
      );
      if (numTransactionItems == 0) {
        _itemDao.markForDeletion(itemId);
      }
      return false;
    }
  }

  Future<void> saveTransaction(
    String name,
    double stocks,
    double price,
    int categoryId,
    int userId,
    String token,
  ) async {
    var item = await _itemDao.getItembyName(name, userId);
    var itemId = item?.id;
    if (item == null) {
      item = Item(
        name: name,
        category:
            await _categoryDao.getCategoryById(categoryId) ??
            Category(id: 0, name: ""),
        transactions: [],
        isSynced: false,
        currentPrice: 0.0,
      );
      itemId = await _itemDao.createItem(item, userId);
    }

    final transaction = Transaction(
      itemId: itemId,
      stocks: stocks,
      purchasePrice: price,
      invEur: stocks * price,
      purchaseDate: DateTime.now(),
      isSynced: false,
    );
    await _transactionDao.saveTransaction(transaction, itemId!);
    syncPendingData(userId, token);
  }

  Future<void> syncPendingData(int userId, String token) async {
    //borro items
    final List<Item> pendingItemDeletes = await _itemDao.getPendingDeletions(
      userId,
    );
    for (var item in pendingItemDeletes) {
      try {
        if (item.serverId != null) {
          final success = await _apiService.delete(
            '/items/${item.serverId}',
            token: token,
          );
          if (success) await _itemDao.deleteItemPhysically(item.id!);
        }
      } catch (e) {
        debugPrint("Error borrando item: $e");
      }
    }
    //borro trans
    final List<Transaction> pendingTransactionDeletes = await _transactionDao
        .getPendingToDelete();

    for (var t in pendingTransactionDeletes) {
      try {
        if (t.serverId != null) {
          final success = await _apiService.delete(
            '/transactions/${t.serverId}',
            token: token,
          );
          if (success) await _transactionDao.deletePhysically(t.id!);
        }
      } catch (e) {
        debugPrint("Error borrando transacción: $e");
      }
    }
    //subo item
    final List<Item> pendingItemSync = await _itemDao.getUnsyncedItems(userId);
    for (var item in pendingItemSync) {
      try {
        if (item.serverId == null) {
          final success = await _apiService.post('/items', {
            'name': item.name,
            'categoryId': item.category.id,
            'transactions': [],
            // 'isSynced': false,
            'currentPrice': 0.0,
            'userId': userId,
            'initialStocks': 0,
          }, token: token);

          if (success != null && success['id'] != null) {
            await _itemDao.markAsSynced(item.id!, success['id']);
          }
        }
      } catch (e) {
        debugPrint("Error subiendo item: $e");
      }
    }
    final List<Transaction> pendingTransactionSync = await _transactionDao
        .getUnsyncTransactions();

    for (var transaction in pendingTransactionSync) {
      try {
        final parentItem = await _itemDao.getItemById(transaction.itemId!);

        if (parentItem != null && parentItem.serverId != null) {
          final response = await _apiService
              .post('/transactions/item/${parentItem.serverId}', {
                'itemId': parentItem.serverId,
                'stocks': transaction.stocks,
                'purchasePrice': transaction.purchasePrice,
                'invEur': transaction.invEur,
                'purchaseDate': transaction.purchaseDate.toIso8601String(),
              }, token: token);
          if (response != null && response['id'] != null) {
            await _transactionDao.markAsSynced(transaction.id!, response['id']);
          }
        }
      } catch (e) {
        debugPrint("Error subiendo trans: $e");
      }
    }
  }
}
