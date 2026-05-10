import 'package:flutter/foundation.dart';
import 'package:investment_tracking/UnauthorizedException.dart';
import '../dao/transaction_dao.dart';
import '../models/transaction.dart';
import '../service/api_service.dart';

class TransactionRepository {
  final ApiService _apiService = ApiService();
  final TransactionDao _transactionDao = TransactionDao();

  /// ELIMINAR: Si falla el servidor, marca con is_deleted = 1
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
          // Si el servidor confirma, borramos físicamente de la app
          await _transactionDao.deletePhysically(localId);
          return true;
        }
      } else {
        // Si no tiene serverId, es que nunca se subió, borramos directo
        await _transactionDao.deletePhysically(localId);
        return true;
      }
      return false;
    } catch (e) {
      if (e is UnauthorizedException) rethrow;
      debugPrint("Offline: Marcando para borrar en el servidor más tarde.");
      // Fallo/Offline: Marcamos para borrado lógico (is_deleted = 1)
      await _transactionDao.markForDeletion(localId);
      return false;
    }
  }

  /// Obtiene transacciones combinando Local + Server si es posible.
  Future<List<Transaction>> getHomeTransactions(
    int userId,
    String token,
  ) async {
    final List<Map<String, dynamic>> maps = await _transactionDao
        .getAllTransactionsForHome(userId);
    return maps.map((m) => Transaction.fromLocalMap(m)).toList();
  }

  //crear nueva transaccion
  Future<void> createTransaction(
    int localItemId,
    int? serverItemId,
    Transaction tx,
    String token,
  ) async {
    final db = await _transactionDao.dbHelper.database;

    try {
      // 1. Guardado Local
      final localMap = tx.toLocalMap(localItemId);
      localMap['is_synced'] = 0;
      final localId = await db.insert('transactions', localMap);
      tx.id = localId;

      // 2. Intento de sincronización con MariaDB
      // Usamos serverItemId y los nombres de campos de la imagen anterior
      final response = await _apiService.post('/transactions', {
        "itemId": serverItemId,
        "stocks": tx.stocks,
        "purchasePrice": tx.purchasePrice,
        "invEur": tx.invEur,

        "purchaseDate": tx.purchaseDate.toIso8601String(),
      }, token: token);

      if (response != null && response['id'] != null) {
        await _transactionDao.markAsSynced(
          localId,
          int.parse(response['id'].toString()),
        );
      }
    } catch (e) {
      if (e is UnauthorizedException) rethrow;
      debugPrint("Modo Offline: Guardado localmente");
    }
  }

  /// SINCRONIZACIÓN TOTAL: Sube creados y ejecuta borrados pendientes
  Future<void> syncAllPendings(String token) async {
    // 1. Procesar ALTAS pendientes (is_synced = 0)
    final List<Map<String, dynamic>> unsyncedRows = await _transactionDao
        .getAllUnsyncedTransactions();

    for (var row in unsyncedRows) {
      try {
        final response = await _apiService.post('/transactions', {
          "itemId": row['item_server_id'],
          "stocks": row['stocks'],
          "purchasePrice": row['purchase_price'],
          "purchaseDate": row['purchase_date'],
          "invEur": row['inv_eur'],
        }, token: token);
        if (response != null && response['id'] != null) {
          final int serverIdFromBack = int.parse(response['id'].toString());
          // Actualizamos SQLite para que ya no aparezca como "pendiente"
          await _transactionDao.markAsSynced(row['id'], serverIdFromBack);
          debugPrint(
            "Transacción local ${row['id']} sincronizada con Server ID: $serverIdFromBack",
          );
        }
      } catch (e) {
        debugPrint("Fallo al subir transacción ${row['id']}: $e");
      }
    }

    // 2. Procesar BAJAS pendientes (is_deleted = 1)
    final List<Map<String, dynamic>> deletionsRows = await _transactionDao
        .getPendingDeletions();

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
        debugPrint("Error sincronizando borrado: $e");
      }
    }
  }
}
