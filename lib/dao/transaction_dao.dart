import 'package:investment_tracking/database/database_helper.dart';

import '../models/transaction.dart';

class TransactionDao {
  final dbHelper = DatabaseHelper.instance;

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
      });
    }
    await batch.commit(noResult: true);
  }
}
