import 'package:flutter_test/flutter_test.dart';
import 'package:investment_tracking/dao/item_dao.dart';
import 'package:investment_tracking/database/database_helper.dart';
import 'package:investment_tracking/models/category.dart';
import 'package:investment_tracking/models/item.dart';
import '../../helpers/db_test_helper.dart';

void main() {
  setUpAll(setUpDatabase);
  tearDownAll(tearDownDatabase);
  setUp(clearAllTables);
  tearDown(clearAllTables);

  group('ItemDao', () {
    late int userId;
    late int catId;

    setUp(() async {
      final db = await DatabaseHelper.instance.database;
      userId = await db.insert('users', {
        'username': 'testuser',
        'email': 'test@user.com',
        'token': 'token',
      });
      catId = await db.insert('categories', {'name': 'TestCategory'});
    });

    test('getItems returns items inserted for the user', () async {
      final db = await DatabaseHelper.instance.database;
      await db.insert('items', {
        'user_id': userId,
        'name': 'TestItem',
        'category_id': catId,
        'is_deleted': 0,
        'current_price': 0.0,
        'is_synced': 1,
      });

      final items = await ItemDao().getItems(userId);

      expect(items.any((item) => item.name == 'TestItem'), isTrue);
    });

    test('createItem and getItemById return the same item', () async {
      final item = Item(
        name: 'TestAsset',
        category: Category(id: catId, name: 'TestCategory'),
        transactions: [],
        currentPrice: 50.0,
      );

      final localId = await ItemDao().createItem(item, userId);
      final fetched = await ItemDao().getItemById(localId);

      expect(fetched, isNotNull);
      expect(fetched?.name, 'TestAsset');
    });

    test('markForDeletion sets is_deleted=1', () async {
      final db = await DatabaseHelper.instance.database;
      final localId = await db.insert('items', {
        'user_id': userId,
        'name': 'ToDelete',
        'category_id': catId,
        'current_price': 0.0,
        'is_synced': 1,
        'is_deleted': 0,
      });

      await ItemDao().markForDeletion(localId);

      final rows = await db.query('items', where: 'id = ?', whereArgs: [localId]);
      expect(rows.first['is_deleted'], 1);
    });

    test('markAsSynced updates server_id and is_synced=1', () async {
      final db = await DatabaseHelper.instance.database;
      final localId = await db.insert('items', {
        'user_id': userId,
        'name': 'ToSync',
        'category_id': catId,
        'current_price': 0.0,
        'is_synced': 0,
        'is_deleted': 0,
      });

      await ItemDao().markAsSynced(localId, 777);

      final rows = await db.query('items', where: 'id = ?', whereArgs: [localId]);
      expect(rows.first['is_synced'], 1);
      expect(rows.first['server_id'], 777);
    });
  });
}
