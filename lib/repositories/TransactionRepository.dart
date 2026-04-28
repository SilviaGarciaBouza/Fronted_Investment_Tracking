import 'package:flutter/foundation.dart';

import '../dao/transaction_dao.dart';
import '../models/transaction.dart';
import '../service/api_service.dart';

class TransactionRepository {
  final ApiService _apiService = ApiService();
  final TransactionDao _transactionDao = TransactionDao();

  /// Obtiene todas las transacciones para el Home (usando el JOIN del DAO)
  Future<List<Transaction>> getHomeTransactions(
    int userId,
    String token,
  ) async {
    try {
      final List<Map<String, dynamic>> maps = await _transactionDao
          .getAllTransactionsForHome(userId);

      return maps.map((m) => Transaction.fromLocalMap(m)).toList();
    } catch (e) {
      final List<Map<String, dynamic>> maps = await _transactionDao
          .getAllTransactionsForHome(userId);
      return maps.map((m) => Transaction.fromLocalMap(m)).toList();
    }
  }

  /// Borra una transacción individual (la papelera del Home)
  Future<bool> deleteTransaction(
    int localId,
    int? serverId,
    String token,
  ) async {
    try {
      if (serverId != null) {
        final success = await _apiService.delete(
          '/transactions/$serverId',
          token: token,
        );
        if (success) {
          await _transactionDao.deletePhysically(localId);
          return true;
        }
      } else {
        await _transactionDao.deletePhysically(localId);
        return true;
      }
      return false;
    } catch (e) {
      await _transactionDao.markForDeletion(localId);
      return false;
    }
  }

  /// Crea una nueva transacción para un ITEM existente (Botón +)
  Future<void> createTransaction(
    int itemId,
    Transaction tx,
    String token,
  ) async {
    try {
      final response = await _apiService.post('/transactions', {
        "itemId": itemId,
        "amount": tx.stocks,
        "purchasePrice": tx.purchasePrice,
        "date": tx.purchaseDate.toIso8601String(),
      }, token: token);

      if (response != null) {
        final newTx = Transaction.fromJson(response);
        await _transactionDao.dbHelper.database.then(
          (db) => db.insert('transactions', newTx.toLocalMap(itemId)),
        );
      }
    } catch (e) {
      final offlineTx = Transaction(
        stocks: tx.stocks,
        purchasePrice: tx.purchasePrice,
        invEur: tx.invEur,
        purchaseDate: tx.purchaseDate,
        isSynced: false,
      );
      await _transactionDao.dbHelper.database.then(
        (db) => db.insert('transactions', offlineTx.toLocalMap(itemId)),
      );
    }
  }

  /// Sincronización completa (El "Push" que te faltaba)
  Future<void> syncEverything(int userId, String token) async {
    final unsynced = await _transactionDao.getUnsyncedTransactions(
      0,
    ); // Ajustar lógica de ID si es necesario
    for (var row in unsynced) {}

    final toDelete = await _transactionDao.getPendingDeletions();
    for (var row in toDelete) {
      try {
        final success = await _apiService.delete(
          '/transactions/${row['server_id']}',
          token: token,
        );
        if (success) await _transactionDao.deletePhysically(row['id']);
      } catch (_) {}
    }
  }

  Future<void> pushPendingTransactions(String token) async {
    final List<Map<String, dynamic>> unsyncedRaw = await _transactionDao
        .getUnsyncedTransactions(0);

    for (var map in unsyncedRaw) {
      try {
        final tx = Transaction.fromLocalMap(map);
        final localId = map['id'];
        final itemId = map['item_id'];

        final response = await _apiService.post('/transactions', {
          "itemId": itemId,
          "amount": tx.stocks,
          "purchasePrice": tx.purchasePrice,
          "date": tx.purchaseDate.toIso8601String(),
        }, token: token);

        if (response != null) {
          final int serverId = int.parse(response['id'].toString());

          await _transactionDao.markAsSynced(localId, serverId);
          debugPrint(
            "Sincronizada transacción local $localId con serverId $serverId",
          );
        }
      } catch (e) {
        debugPrint("Error al sincronizar transacción local: $e");
      }
    }
  }

  Future<void> syncAllPendings(String token) async {
    final List<Map<String, dynamic>> unsyncedRows = await _transactionDao
        .getAllUnsyncedTransactions();
    final List<Map<String, dynamic>> deletionsRows = await _transactionDao
        .getPendingDeletions();

    for (var row in unsyncedRows) {
      try {
        final response = await _apiService.post('/transactions', {
          "itemId": row['item_id'], // El ID del activo padre
          "amount": row['stocks'],
          "purchasePrice": row['purchase_price'],
          "date": row['purchase_date'],
        }, token: token);

        if (response != null) {
          final int serverIdFromBack = int.parse(response['id'].toString());
          await _transactionDao.markAsSynced(row['id'], serverIdFromBack);
        }
      } catch (e) {
        debugPrint("Error subiendo transacción ${row['id']}: $e");
        rethrow;
      }
    }

    for (var row in deletionsRows) {
      try {
        final bool success = await _apiService.delete(
          '/transactions/${row['server_id']}',
          token: token,
        );
        if (success) {
          await _transactionDao.deletePhysically(row['id']);
        }
      } catch (e) {
        debugPrint("Error borrando en servidor ${row['server_id']}: $e");
        rethrow;
      }
    }
  }
}
