import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:investment_tracking/database/database_helper.dart';
import 'package:investment_tracking/exceptions/Server_unavailable_exception.dart';
import 'package:investment_tracking/models/category.dart';
import 'package:investment_tracking/models/item.dart';
import 'package:investment_tracking/repositories/item_repository.dart';
import '../../helpers/db_test_helper.dart';
import '../../helpers/http_mock.dart';

void main() {
  setUpAll(() async {
    HttpOverrides.global = MockHttpOverrides((url) async {
      if (url.path.contains('/items')) {
        return MockHttpResponse(json.encode({'id': 99, 'name': 'Gold'}));
      }
      if (url.path.contains('/transactions')) {
        return MockHttpResponse(json.encode({'id': 55}), 201);
      }
      return MockHttpResponse('[]');
    });
    await setUpDatabase();
  });

  tearDownAll(tearDownDatabase);
  setUp(clearAllTables);
  tearDown(clearAllTables);

  group('ItemRepository', () {
    late int userId;
    late int catId;

    setUp(() async {
      final db = await DatabaseHelper.instance.database;
      userId = await db.insert('users', {
        'username': 'testuser',
        'email': 'test@user.com',
        'token': 'token',
      });
      catId = await db.insert('categories', {'name': 'Metals'});
    });

    test('getLocalItems returns user items from SQLite', () async {
      final db = await DatabaseHelper.instance.database;
      await db.insert('items', {
        'user_id': userId,
        'name': 'Silver',
        'category_id': catId,
        'current_price': 25.0,
        'is_synced': 1,
        'is_deleted': 0,
      });

      final items = await ItemRepository().getLocalItems(userId);

      expect(items.any((i) => i.name == 'Silver'), isTrue);
    });

    test(
      'deleteItem without serverId deletes physically and returns true',
      () async {
        final db = await DatabaseHelper.instance.database;
        final localId = await db.insert('items', {
          'user_id': userId,
          'name': 'ToDelete',
          'category_id': catId,
          'current_price': 0.0,
          'is_synced': 0,
          'is_deleted': 0,
        });

        final result = await ItemRepository().deleteItem(
          localId,
          null,
          'token',
        );

        expect(result, isTrue);
        final rows = await db.query(
          'items',
          where: 'id = ?',
          whereArgs: [localId],
        );
        expect(rows, isEmpty);
      },
    );

    test('saveItem creates item locally when server fails', () async {
      HttpOverrides.global = MockHttpOverrides((_) async {
        throw const SocketException('sin red');
      });

      final item = Item(
        name: 'OfflineItem',
        category: Category(id: catId, name: 'Metals'),
        transactions: [],
        currentPrice: 0.0,
      );

      try {
        await ItemRepository().saveItem(item, 10.0, 5.0, userId, 'token');
      } on ServerUnavailableException {
        // expected — server unreachable, item saved locally
      }

      final items = await ItemRepository().getLocalItems(userId);
      expect(items.any((i) => i.name == 'OfflineItem'), isTrue);
    });
  });
}
