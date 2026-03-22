import 'package:investment_tracking/database/database_helper.dart';
import 'package:sqflite/sqflite.dart' hide Transaction;
import '../models/transaction.dart';

/// Clase encargada de la persistencia de las transacciones financieras.
class TransactionDao {
  final dbHelper = DatabaseHelper.instance;

  /// Sincroniza las transacciones de un item específico, eliminando las antiguas y guardando las nuevas.
  Future<void> syncTransactions(List<Transaction> txs, int itemId) async {
    final db = await dbHelper.database;
    final batch = db.batch();

    batch.delete('transactions', where: 'item_id = ?', whereArgs: [itemId]);

    for (var tx in txs) {
      batch.insert('transactions', {
        'id': tx.id,
        'item_id': itemId,
        'stocks': tx.stocks,
        'purchase_price': tx.purchasePrice,
        'inv_eur': tx.invEur,
        'purchase_date': tx.purchaseDate.toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }
}
