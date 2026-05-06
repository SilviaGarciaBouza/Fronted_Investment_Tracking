import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:investment_tracking/database/database_helper.dart';
import 'package:investment_tracking/models/transaction.dart';
import 'package:investment_tracking/repositories/TransactionRepository.dart';
import '../../helpers/db_test_helper.dart';
import '../../helpers/http_mock.dart';

void main() {
  setUpAll(() async {
    HttpOverrides.global = MockHttpOverrides((url) async {
      if (url.path.contains('/transactions')) {
        return MockHttpResponse(json.encode({'id': 88}), 201);
      }
      return MockHttpResponse('[]');
    });
    await setUpDatabase();
  });

  tearDownAll(tearDownDatabase);
  setUp(clearAllTables);
  tearDown(clearAllTables);

  group('TransactionRepository', () {
    late int userId;
    late int itemId;

    setUp(() async {
      final db = await DatabaseHelper.instance.database;
      userId = await db.insert('users', {
        'username': 'testuser',
        'email': 'test@user.com',
        'token': 'token',
      });
      final catId = await db.insert('categories', {'name': 'Crypto'});
      itemId = await db.insert('items', {
        'user_id': userId,
        'name': 'Bitcoin',
        'category_id': catId,
        'current_price': 50000.0,
        'is_synced': 1,
        'is_deleted': 0,
        'server_id': 10,
      });
    });

    test('deleteTransaction without serverId deletes physically and returns true',
        () async {
      final db = await DatabaseHelper.instance.database;
      final localId = await db.insert('transactions', {
        'item_id': itemId,
        'stocks': 1.0,
        'purchase_price': 50000.0,
        'inv_eur': 50000.0,
        'purchase_date': DateTime.now().toIso8601String(),
        'is_synced': 0,
        'is_deleted': 0,
      });

      final result = await TransactionRepository().deleteTransaction(
        localId,
        null,
        'token',
      );

      expect(result, isTrue);
      final rows = await db
          .query('transactions', where: 'id = ?', whereArgs: [localId]);
      expect(rows, isEmpty);
    });

    test('getHomeTransactions returns empty list when there are no transactions',
        () async {
      final txs =
          await TransactionRepository().getHomeTransactions(userId, 'token');

      expect(txs, isEmpty);
    });

    test('createTransaction saves locally and syncs with server',
        () async {
      final tx = Transaction(
        itemId: itemId,
        stocks: 0.5,
        purchasePrice: 48000.0,
        invEur: 24000.0,
        purchaseDate: DateTime(2024, 1, 15),
        isSynced: false,
      );

      await TransactionRepository().createTransaction(
        itemId,
        10,
        tx,
        'token',
      );

      final db = await DatabaseHelper.instance.database;
      final rows = await db.query(
        'transactions',
        where: 'item_id = ?',
        whereArgs: [itemId],
      );
      expect(rows, isNotEmpty);
      expect(rows.first['is_synced'], 1);
      expect(rows.first['server_id'], 88);
    });
  });
}
