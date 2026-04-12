import 'package:flutter_test/flutter_test.dart';
import 'package:investment_tracking/dao/caegory_dao.dart';
import 'package:investment_tracking/dao/item_dao.dart';
import 'package:investment_tracking/dao/transaction_dao.dart';
import 'package:investment_tracking/dao/user_dao.dart';
import 'package:investment_tracking/database/database_helper.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late DatabaseHelper dbHelper;
  late ItemDao itemDao;
  late CategoryDao categoryDao;
  late UserDao userDao;
  late TransactionDao transactionDao;
  Future<void> clearDatabase(Database db) async {
    await db.delete('transactions');
    await db.delete('items');
    await db.delete('categories');
    await db.delete('users');
  }

  setUp(() async {
    dbHelper = DatabaseHelper.instance;
    itemDao = ItemDao();
    categoryDao = CategoryDao();
    userDao = UserDao();
    transactionDao = TransactionDao();
    final db = await dbHelper.database;
    await db.delete('transactions');
    await db.delete('items');
    await db.delete('categories');
    await db.delete('users');
  });

  tearDown(() async {
    final db = await dbHelper.database;
    await db.delete('transactions');
    await db.delete('items');
    await db.delete('categories');
    await db.delete('users');
  });

  group('CategoryDao', () {
    test('insert and get category', () async {
      final db = await dbHelper.database;

      await db.insert('categories', {'name': 'TestCat'});

      final categories = await categoryDao.getCategories();

      expect(categories.any((c) => c.name == 'TestCat'), isTrue);
    });
  });

  group('UserDao', () {
    late UserDao userDao;

    setUp(() async {
      userDao = UserDao();
      final db = await DatabaseHelper.instance.database;
      await db.delete('users');
    });

    test('insert and get user', () async {
      final db = await DatabaseHelper.instance.database;

      await db.insert('users', {
        'id': 1,
        'username': 'user1',
        'email': 'user1@test.com',
        'token': 'token_ejemplo',
      });

      final user = await userDao.getUser();

      expect(user, isNotNull);
      expect(user?.username, 'user1');
    });
  });

  group('TransactionDao', () {
    test('insert and get unsynced transactions', () async {
      final db = await dbHelper.database;
      final catId = await db.insert('categories', {'name': 'Cat2'});
      final itemId = await db.insert('items', {
        'name': 'Item2',
        'category_id': catId,
      });
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
      final unsynced = await transactionDao.getUnsyncedTransactions(itemId);
      expect(unsynced.length, 1);
      expect((unsynced.first['stocks'] as num).toDouble(), 5.0);
    });
  });
  group('ItemDao', () {
    late int categoryId;
    late int userId;

    setUp(() async {
      final db = await dbHelper.database;
      await db.delete('items');
      await db.delete('categories');
      await db.delete('users');
      userId = await db.insert('users', {
        'username': 'testuser',
        'email': 'test@user.com',
        'token': 'token',
      });
      categoryId = await db.insert('categories', {'name': 'TestCategory'});
    });

    test('insert and get item', () async {
      final db = await dbHelper.database;
      await db.insert('items', {
        'user_id': userId,
        'name': 'TestItem',
        'category_id': categoryId,
        'is_deleted': 0,
        'current_price': 0.0,
        'is_synced': 1,
      });

      final items = await itemDao.getItems(categoryId);

      expect(items.any((item) => item.name == 'TestItem'), isTrue);
    });
  });
}
