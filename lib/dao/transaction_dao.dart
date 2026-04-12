import 'package:investment_tracking/database/database_helper.dart';
import '../models/transaction.dart';

/// Gestión de persistencia para las operaciones financieras (compras/ventas).
class TransactionDao {
  final dbHelper = DatabaseHelper.instance;

  /// Sincroniza las transacciones de un activo provenientes del servidor.
  ///
  /// Borra las transacciones locales que ya estaban marcadas como sincronizadas
  /// para evitar duplicados y guarda la versión "oficial" del backend.
  Future<void> syncTransactions(List<Transaction> txs, int localItemId) async {
    final db = await dbHelper.database;
    final batch = db.batch();

    batch.delete(
      'transactions',
      where: 'item_id = ? AND is_synced = 1',
      whereArgs: [localItemId],
    );

    for (var tx in txs) {
      batch.insert('transactions', {
        'server_id': tx.serverId,
        'item_id': localItemId,
        'stocks': tx.stocks,
        'purchase_price': tx.purchasePrice,
        'inv_eur': tx.invEur,
        'purchase_date': tx.purchaseDate.toIso8601String(),
        'is_synced': 1,
      });
    }
    await batch.commit(noResult: true);
  }

  /// Recupera las transacciones de un item que aún no se han subido a MariaDB.
  Future<List<Map<String, dynamic>>> getUnsyncedTransactions(
    int localItemId,
  ) async {
    final db = await dbHelper.database;
    return await db.query(
      'transactions',
      where: 'item_id = ? AND is_synced = 0',
      whereArgs: [localItemId],
    );
  }
}
