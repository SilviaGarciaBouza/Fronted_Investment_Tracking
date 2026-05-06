import 'package:flutter_test/flutter_test.dart';
import 'package:investment_tracking/dao/transaction_dao.dart';
import 'package:investment_tracking/database/database_helper.dart';
import 'package:investment_tracking/models/transaction.dart';
import '../../helpers/db_test_helper.dart';

Future<int> _seedItem() async {
  final db = await DatabaseHelper.instance.database;
  final userId = await db.insert('users', {
    'username': 'u',
    'email': 'e@test.com',
    'token': 't',
  });
  final catId = await db.insert('categories', {'name': 'C'});
  return db.insert('items', {
    'user_id': userId,
    'name': 'I',
    'category_id': catId,
    'current_price': 0.0,
    'is_synced': 1,
    'is_deleted': 0,
  });
}

void main() {
  setUpAll(setUpDatabase);
  tearDownAll(tearDownDatabase);
  setUp(clearAllTables);
  tearDown(clearAllTables);

  group('TransactionDao', () {
    test('getUnsyncedTransactions filters by is_synced=0', () async {
      final db = await DatabaseHelper.instance.database;
      final itemId = await _seedItem();
      await db.insert('transactions', {
        'item_id': itemId,
        'stocks': 1.0,
        'purchase_price': 10.0,
        'inv_eur': 10.0,
        'is_synced': 1,
        'purchase_date': '2026-01-01',
      });
      await db.insert('transactions', {
        'item_id': itemId,
        'stocks': 5.0,
        'purchase_price': 10.0,
        'inv_eur': 50.0,
        'is_synced': 0,
        'purchase_date': '2026-02-01',
      });

      final unsynced = await TransactionDao().getUnsyncedTransactions(itemId);

      expect(unsynced.length, 1);
      expect((unsynced.first['stocks'] as num).toDouble(), 5.0);
    });

    test('saveTransaction inserts row and getTransactionItemsCount returns 1',
        () async {
      final itemId = await _seedItem();
      final tx = Transaction(
        stocks: 2.0,
        purchasePrice: 100.0,
        invEur: 200.0,
        purchaseDate: DateTime(2026, 1, 1),
      );

      await TransactionDao().saveTransaction(tx, itemId);

      expect(await TransactionDao().getTransactionItemsCount(itemId), 1);
    });

    test('markForDeletion sets is_deleted=1', () async {
      final db = await DatabaseHelper.instance.database;
      final itemId = await _seedItem();
      final txId = await db.insert('transactions', {
        'item_id': itemId,
        'stocks': 1.0,
        'purchase_price': 10.0,
        'inv_eur': 10.0,
        'is_synced': 1,
        'is_deleted': 0,
        'purchase_date': '2026-01-01',
      });

      await TransactionDao().markForDeletion(txId);

      final rows = await db.query(
        'transactions',
        where: 'id = ?',
        whereArgs: [txId],
      );
      expect(rows.first['is_deleted'], 1);
    });

    test('markAsSynced updates server_id and is_synced=1', () async {
      final db = await DatabaseHelper.instance.database;
      final itemId = await _seedItem();
      final txId = await db.insert('transactions', {
        'item_id': itemId,
        'stocks': 1.0,
        'purchase_price': 10.0,
        'inv_eur': 10.0,
        'is_synced': 0,
        'is_deleted': 0,
        'purchase_date': '2026-01-01',
      });

      await TransactionDao().markAsSynced(txId, 999);

      final rows = await db.query(
        'transactions',
        where: 'id = ?',
        whereArgs: [txId],
      );
      expect(rows.first['is_synced'], 1);
      expect(rows.first['server_id'], 999);
    });
  });
}
