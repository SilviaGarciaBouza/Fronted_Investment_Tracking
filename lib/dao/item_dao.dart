import 'package:flutter/foundation.dart';
import '../database/database_helper.dart';
import '../dao/transaction_dao.dart';
import '../models/item.dart';
import '../models/transaction.dart';

/// DAO central para la gestión de items.
/// Coordina la persistencia en SQLite y la relación con las transacciones.
class ItemDao {
  final dbHelper = DatabaseHelper.instance;
  final transactionDao = TransactionDao();

  /// Guarda los datos del servidor en SQLite.
  Future<void> saveItems(List<Item> items, int userId) async {
    final db = await dbHelper.database;
    await db.transaction((txn) async {
      List<int> serverIdsRecibidos = [];
      for (var item in items) {
        if (item.serverId != null) serverIdsRecibidos.add(item.serverId!);
        final List<Map<String, dynamic>> existing = await txn.query(
          'items',
          where: 'server_id = ? AND user_id = ?',
          whereArgs: [item.serverId, userId],
        );
        int localId;
        if (existing.isNotEmpty) {
          localId = existing.first['id'];
          await txn.update(
            'items',
            {
              'server_id': item.serverId,
              'category_id': item.category.id,
              'current_price': item.currentPrice,
              'is_synced': 1,
              'is_deleted': 0,
            },
            where: 'id = ?',
            whereArgs: [localId],
          );
        } else {
          final map = item.toLocalMap(userId);
          map['is_synced'] = 1;
          localId = await txn.insert('items', map);
        }
        // Sincronizar las transacciones.
        // Borramos las locales sincronizadas para evitar duplicados
        await txn.delete(
          'transactions',
          where: 'item_id = ? AND is_synced = 1',
          whereArgs: [localId],
        );
        // Insertamos la lista que viene del servidor
        for (var tx in item.transactions) {
          await txn.insert('transactions', {
            'server_id': tx.serverId,
            'item_id': localId,
            'stocks': tx.stocks,
            'purchase_price': tx.purchasePrice,
            'inv_eur': tx.invEur,
            'purchase_date': tx.purchaseDate.toIso8601String(),
            'is_synced': 1,
          });
        }
      }
      // Eliminar localmente lo que el servidor ya no tiene
      if (serverIdsRecibidos.isNotEmpty) {
        await txn.delete(
          'items',
          where:
              'user_id = ? AND server_id IS NOT NULL AND server_id NOT IN (${serverIdsRecibidos.join(',')})',
          whereArgs: [userId],
        );
      }
    });
    debugPrint("Sincronización DAO: Base local actualizada con éxito.");
  }

  /// Recupera los activos visibles (no borrados lógicamente).
  Future<List<Item>> getItems(int userId) async {
    final db = await dbHelper.database;

    final List<Map<String, dynamic>> itemMaps = await db.rawQuery(
      '''
    SELECT items.*, categories.name as category_name 
    FROM items 
    INNER JOIN categories ON items.category_id = categories.id 
    WHERE items.user_id = ? AND items.is_deleted = 0
    ''',
      [userId],
    );

    List<Item> reconstruidos = [];
    for (var map in itemMaps) {
      final List<Map<String, dynamic>> txMaps = await db.query(
        'transactions',
        where: 'item_id = ? AND is_deleted = 0',
        whereArgs: [map['id']],
      );

      final List<Transaction> transactions = txMaps
          .map((t) => Transaction.fromLocalMap(t))
          .toList();

      reconstruidos.add(Item.fromLocalMap(map, transactions));
    }
    return reconstruidos;
  }

  //getItemByname
  Future<Item?> getItembyName(String name, int userId) async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'items',
      where: 'name = ? AND user_id = ? AND is_deleted = 0',
      whereArgs: [name, userId],
    );
    if (maps.isNotEmpty) {
      final List<Map<String, dynamic>> txMaps = await db.query(
        'transactions',
        where: 'item_id = ? AND is_deleted = 0',
        whereArgs: [maps.first['id']],
      );
      final List<Transaction> transactions = txMaps
          .map((t) => Transaction.fromLocalMap(t))
          .toList();
      return Item.fromLocalMap(maps.first, transactions);
    }
    return null;
  }

  //createItem
  Future<int> createItem(Item item, int userId) async {
    final db = await dbHelper.database;
    return await db.insert('items', item.toLocalMap(userId));
  }

  //_______________________________________________---
  /// Guarda un activo nuevo creado sin conexión.
  Future<void> saveItemOffline(
    Item item,
    double stocks,
    double price,
    int userId,
  ) async {
    final db = await dbHelper.database;
    final map = item.toLocalMap(userId);
    map['is_synced'] = 0;

    final idGenerado = await db.insert('items', map);

    // Creamos la transacción inicial vinculada
    await db.insert('transactions', {
      'item_id': idGenerado,
      'stocks': stocks,
      'purchase_price': price,
      'inv_eur': stocks * price,
      'purchase_date': DateTime.now().toIso8601String(),
      'is_synced': 0,
    });
  }

  /// Obtiene los ítems creados offline pendientes de subir al servidor.
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
      unsynced.add(
        Item.fromLocalMap(
          map,
          txMaps.map((t) => Transaction.fromLocalMap(t)).toList(),
        ),
      );
    }
    return unsynced;
  }

  /// Borrado lógico: Oculta el item de la lista hasta que haya red para borrarlo en MariaDB.
  Future<void> markForDeletion(int localId) async {
    final db = await dbHelper.database;
    await db.update(
      'items',
      {'is_deleted': 1},
      where: 'id = ?',
      whereArgs: [localId],
    );
  }

  Future<void> markAsSynced(int localId, int serverId) async {
    final db = await dbHelper.database;
    await db.update(
      'items',
      {'server_id': serverId, 'is_synced': 1},
      where: 'id = ?',
      whereArgs: [localId],
    );
  }

  /// Borrado físico: Elimina el registro de SQLite (dispara el CASCADE de transacciones).
  Future<void> deleteItemPhysically(int localId) async {
    final db = await dbHelper.database;
    await db.delete('items', where: 'id = ?', whereArgs: [localId]);
  }

  /// Obtiene los items que el usuario borró estando offline.
  Future<List<Item>> getPendingDeletions(int userId) async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'items',
      where: 'user_id = ? AND is_deleted = 1',
      whereArgs: [userId],
    );

    List<Item> toDelete = [];
    for (var map in maps) {
      toDelete.add(Item.fromLocalMap(map, []));
    }
    return toDelete;
  }

  Future<Item?> getItemById(int id) async {
    final db = await dbHelper.database;

    final List<Map<String, dynamic>> maps = await db.query(
      'items',
      where: 'id = ? AND is_deleted = 0',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      final List<Map<String, dynamic>> txMaps = await db.query(
        'transactions',
        where: 'item_id = ? AND is_deleted = 0',
        whereArgs: [id],
      );

      final List<Transaction> transactions = txMaps
          .map((t) => Transaction.fromLocalMap(t))
          .toList();

      return Item.fromLocalMap(maps.first, transactions);
    }

    return null;
  }
}
