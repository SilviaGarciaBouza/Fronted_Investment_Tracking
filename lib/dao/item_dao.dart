import 'package:flutter/foundation.dart';
import 'package:investment_tracking/dao/transaction_dao.dart';
import 'package:investment_tracking/database/database_helper.dart';
import 'package:sqflite/sqflite.dart';
import '../models/item.dart';

/// Clase principal para la gestión de activos (Items) y su estado de sincronización.
class ItemDao {
  final dbHelper = DatabaseHelper.instance;
  final transactionDao = TransactionDao();

  /// Guarda los items provenientes del servidor y los marca como sincronizados.
  /* Future<void> saveItems(List<Item> items, int userId) async {
    final db = await dbHelper.database;
    final batch = db.batch();

    for (var item in items) {
      final map = item.toLocalMap(userId);
      map['is_synced'] = 1;
      map['is_deleted'] = 0;

      batch.insert('items', map, conflictAlgorithm: ConflictAlgorithm.replace);
      await transactionDao.syncTransactions(item.transactions, item.id);
    }

    await batch.commit(noResult: true);
    debugPrint("${items.length} inversiones sincronizadas y guardadas.");
  }*/

  /// Obtiene los items creados localmente que aún no se han subido al servidor.
  Future<List<Item>> getUnsyncedItems(int userId) async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'items',
      where: 'user_id = ? AND is_synced = 0 AND is_deleted = 0',
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

  /*
  Future<void> saveItems(List<Item> items, int userId) async {
    final db = await dbHelper.database;

    for (var item in items) {
      final map = item.toLocalMap(userId);
      map['is_synced'] = 1;
      map['is_deleted'] = 0;

      await db.insert(
        'items',
        map,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      if (item.transactions != null && item.transactions.isNotEmpty) {
        await transactionDao.syncTransactions(item.transactions, item.id);
      }
    }

    debugPrint("${items.length} inversiones sincronizadas y guardadas.");
  }*/
  /// Sincroniza y persiste los activos provenientes del servidor en la base de datos local.
  Future<void> saveItems(List<Item> items, int userId) async {
    final db = await dbHelper.database;

    for (var item in items) {
      final List<Map<String, dynamic>> existing = await db.query(
        'items',
        where: 'name = ? AND user_id = ?',
        whereArgs: [item.name, userId],
      );

      if (existing.isNotEmpty) {
        final localItem = existing.first;
        int localId = localItem['id'];

        if (localItem['is_deleted'] == 1) continue;

        if (localId != item.id) {
          print("FUSIONANDO: Migrando datos de $localId al ID real ${item.id}");

          await db.update(
            'transactions',
            {'item_id': item.id},
            where: 'item_id = ?',
            whereArgs: [localId],
          );

          await db.delete('items', where: 'id = ?', whereArgs: [localId]);
        }
      }

      final map = item.toLocalMap(userId);
      map['is_synced'] = 1;
      map['is_deleted'] = 0;

      await db.insert(
        'items',
        map,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      if (item.transactions.isNotEmpty) {
        await transactionDao.syncTransactions(item.transactions, item.id);
      }
    }
    debugPrint("${items.length} inversiones procesadas sin duplicados.");
  }

  /// Cambia el estado de un item a sincronizado tras una subida exitosa.
  Future<void> markAsSynced(int itemId) async {
    final db = await dbHelper.database;
    await db.update(
      'items',
      {'is_synced': 1},
      where: 'id = ?',
      whereArgs: [itemId],
    );
  }

  /// Elimina físicamente un item de la base de datos local.
  Future<void> deleteItem(int itemId) async {
    final db = await dbHelper.database;
    await db.delete('items', where: 'id = ?', whereArgs: [itemId]);
  }

  /// Borra todos los items de la tabla local.
  Future<void> deleteAllItems() async {
    final db = await dbHelper.database;
    await db.delete('items');
  }

  /// Marca un item para ser borrado en la próxima sincronización con el servidor.
  Future<void> markForDeletion(int localId) async {
    final db = await dbHelper.database;
    await db.update(
      'items',
      {'is_deleted': 1},
      where: 'id = ?',
      whereArgs: [localId],
    );
  }

  /// Elimina de la base de datos local todos los items que ya están en el servidor.
  Future<void> deleteSyncedItems() async {
    final db = await dbHelper.database;
    await db.delete('items', where: 'is_synced = 1');
  }

  /// Recupera los items marcados para borrar que ya existían en el servidor.
  Future<List<Map<String, dynamic>>> getPendingDeletions() async {
    final db = await dbHelper.database;
    return await db.query('items', where: 'is_deleted = 1 AND is_synced = 1');
  }

  /// Guarda una nueva inversión de forma local cuando no hay conexión.
  Future<void> saveItemOffline(
    Item item,
    double stocks,
    double price,
    int userId,
  ) async {
    final db = await dbHelper.database;

    final map = item.toLocalMap(userId);
    map['is_synced'] = 0;
    map['is_deleted'] = 0;
    final int idGenerado = await db.insert(
      'items',
      map,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    await db.insert('transactions', {
      'item_id': idGenerado,
      'stocks': stocks,
      'purchase_price': price,
      'inv_eur': stocks * price,
      'purchase_date': DateTime.now().toIso8601String(),
    });

    print("SQLite: Guardado item $idGenerado con $stocks stocks.");
  }

  /// Obtiene todos los activos activos de un usuario que no están marcados para borrar.
  Future<List<Item>> getItems(int userId) async {
    final db = await dbHelper.database;

    final List<Map<String, dynamic>> itemMaps = await db.query(
      'items',
      where: 'user_id = ? AND is_deleted = 0',
      whereArgs: [userId],
    );

    List<Item> reconstruidos = [];
    for (var map in itemMaps) {
      final List<Map<String, dynamic>> txMaps = await db.query(
        'transactions',
        where: 'item_id = ?',
        whereArgs: [map['id']],
      );
      reconstruidos.add(Item.fromLocalMap(map, txMaps));
    }
    return reconstruidos;
  }
}
