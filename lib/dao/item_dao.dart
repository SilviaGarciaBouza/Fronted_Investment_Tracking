import 'package:investment_tracking/dao/transaction_dao.dart';
import 'package:investment_tracking/database/database_helper.dart';
import 'package:sqflite/sqflite.dart';
import '../models/item.dart';

class ItemDao {
  final dbHelper = DatabaseHelper.instance;
  final transactionDao = TransactionDao();

  Future<void> saveItems(List<Item> items, int userId) async {
    final db = await dbHelper.database;
    final batch = db.batch();

    for (var item in items) {
      final map = item.toLocalMap(userId);
      map['is_synced'] = 1;

      batch.insert('items', map, conflictAlgorithm: ConflictAlgorithm.replace);
      await transactionDao.syncTransactions(item.transactions, item.id);
    }

    await batch.commit(noResult: true);
    print("${items.length} inversiones sincronizadas y guardadas.");
  }

  Future<void> saveItemOffline(Item item, int userId) async {
    final db = await dbHelper.database;
    final map = item.toLocalMap(userId);
    map['is_synced'] = 0;

    await db.insert('items', map, conflictAlgorithm: ConflictAlgorithm.replace);
    await transactionDao.syncTransactions(item.transactions, item.id);
  }

  Future<List<Item>> getUnsyncedItems(int userId) async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'items',
      where: 'user_id = ? AND is_synced = 0',
      whereArgs: [userId],
    );

    List<Item> unsynced = [];
    for (var map in maps) {
      final List<Map<String, dynamic>> txMaps = await db.query(
        'transactions',
        where: 'item_id = ?',
        whereArgs: [map['id']],
      );
      unsynced.add(Item.fromLocalMap(map, txMaps));
    }
    return unsynced;
  }

  Future<void> markAsSynced(int itemId) async {
    final db = await dbHelper.database;
    await db.update(
      'items',
      {'is_synced': 1},
      where: 'id = ?',
      whereArgs: [itemId],
    );
  }

  Future<List<Item>> getItems(int userId) async {
    final db = await dbHelper.database;

    final List<Map<String, dynamic>> itemMaps = await db.query(
      'items',
      where: 'user_id = ?',
      whereArgs: [userId],
    );

    List<Item> itemsReconstruidos = [];

    for (var itemMap in itemMaps) {
      final List<Map<String, dynamic>> txMaps = await db.query(
        'transactions',
        where: 'item_id = ?',
        whereArgs: [itemMap['id']],
      );

      itemsReconstruidos.add(Item.fromLocalMap(itemMap, txMaps));
    }

    print("Recuperados ${itemsReconstruidos.length} items de SQLite.");
    return itemsReconstruidos;
  }

  Future<void> deleteItem(int itemId) async {
    final db = await dbHelper.database;
    await db.delete('items', where: 'id = ?', whereArgs: [itemId]);
  }

  Future<void> deleteAllItems() async {
    final db = await dbHelper.database;
    await db.delete('items');
  }
}
