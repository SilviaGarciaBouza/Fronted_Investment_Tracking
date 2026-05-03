import 'package:investment_tracking/database/database_helper.dart';
import 'package:sqflite/sqflite.dart' hide Transaction;
import '../models/transaction.dart';

/// Gestión de persistencia para las operaciones financieras (compras/ventas).
class TransactionDao {
  final dbHelper = DatabaseHelper.instance;

  /// Para borrar desde la papelera del Home

  Future<void> markForDeletion(int localId) async {
    final db = await dbHelper.database;
    await db.update(
      'transactions',
      {'is_deleted': 1},
      where: 'id = ?',
      whereArgs: [localId],
    );
  }

  /// Borrado físico tras sincronizar con el Back
  Future<void> deletePhysically(int localId) async {
    final db = await dbHelper.database;
    await db.delete('transactions', where: 'id = ?', whereArgs: [localId]);
  }

  /// Obtiene el número de transacciones activas de un activo específico.
  Future<int> getTransactionItemsCount(int itemId) async {
    final db = await dbHelper.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) FROM transactions WHERE item_id = ? AND is_deleted = 0',
      [itemId],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Obtiene el número de transacciones generico de un activo específico.
  Future<int> getTransactionItemsCountTotal(int itemId) async {
    final db = await dbHelper.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) FROM transactions WHERE item_id = ?',
      [itemId],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }
  //saveTransaction al item le añadimpos esta tranasaccion

  Future<int> saveTransaction(Transaction transaction, int itemId) async {
    final db = await dbHelper.database;
    return await db.insert('transactions', transaction.toLocalMap(itemId));
  }

  //____________________________-
  /// Sincroniza las transacciones de un activo provenientes del servidor.
  /// Borra las transacciones locales que ya estaban marcadas como sincronizadas
  /// para evitar duplicados y guarda la versión "oficial" del backend.
  Future<void> syncTransactions(List<Transaction> txs, int localItemId) async {
    final db = await dbHelper.database;
    final batch = db.batch();

    batch.delete(
      'transactions',
      where: 'item_id = ? AND is_synced = 1 AND is_deleted = 0',
      whereArgs: [localItemId],
    );

    for (var tx in txs) {
      batch.rawInsert(
        '''
      INSERT INTO transactions (server_id, item_id, stocks, purchase_price, inv_eur, purchase_date, is_synced, is_deleted)
      SELECT ?, ?, ?, ?, ?, ?, 1, 0
      WHERE NOT EXISTS (SELECT 1 FROM transactions WHERE server_id = ? AND is_deleted = 1)
    ''',
        [
          tx.serverId,
          localItemId,
          tx.stocks,
          tx.purchasePrice,
          tx.invEur,
          tx.purchaseDate.toIso8601String(),
          tx.serverId,
        ],
      );
    }
    await batch.commit(noResult: true);
  }

  /// Recupera las transacciones de un item que aún no se han subido a MariaDB.
  Future<List<Map<String, dynamic>>> getUnsyncedTransactions(
    int localItemId,
  ) async {
    final db = await dbHelper.database;
    return await db.query(
      'transactions',
      where: 'item_id = ? AND is_synced = 0',
      whereArgs: [localItemId],
    );
  }

  /// Obtiene los ítems creados offline pendientes de subir al servidor.
  Future<List<Transaction>> getUnsyncTransactions(int userId) async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      where: 'user_id = ? AND is_synced = 0 AND is_deleted = 0',
      whereArgs: [userId],
    );
    List<Transaction> unsynced = [];
    for (var map in maps) {
      unsynced.add(Transaction.fromLocalMap(map));
    }
    return unsynced;
  }

  /// Obtiene todo para el Home
  Future<List<Map<String, dynamic>>> getAllTransactionsForHome(
    int userId,
  ) async {
    final db = await dbHelper.database;

    // Aquí es donde unimos Transaction + Item + Category
    return await db.rawQuery(
      '''
      SELECT 
        t.*, 
        i.name as item_name, 
        c.name as category_name
      FROM transactions t
      INNER JOIN items i ON t.item_id = i.id
      INNER JOIN categories c ON i.category_id = c.id
      WHERE i.user_id = ? AND t.is_deleted = 0
      ORDER BY t.purchase_date DESC
    ''',
      [userId],
    );
  }

  /// Obtiene las transacciones marcadas para borrar que existen en el servidor
  Future<List<Map<String, dynamic>>> getPendingDeletions() async {
    final db = await dbHelper.database;
    return await db.query(
      'transactions',
      where: 'is_deleted = 1 AND server_id IS NOT NULL',
    );
  }

  /// Obtiene las transacciones marcadas para borrar que existen en el servidor
  Future<List<Transaction>> getPendingToDelete() async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      where: 'is_deleted = 1 AND server_id IS NOT NULL',
    );
    List<Transaction> toDelete = [];
    for (var map in maps) {
      toDelete.add(Transaction.fromLocalMap(map));
    }
    return toDelete;
  }

  /// Obtiene ABSOLUTAMENTE TODAS las transacciones pendientes de subir (is_synced = 0)
  /// de cualquier activo.
  Future<List<Map<String, dynamic>>> getAllUnsyncedTransactions() async {
    final db = await dbHelper.database;
    return await db.rawQuery('''
    SELECT 
      t.*, 
      i.server_id as item_server_id 
    FROM transactions t
    INNER JOIN items i ON t.item_id = i.id
    WHERE t.is_synced = 0 AND t.is_deleted = 0 AND i.server_id IS NOT NULL
  ''');
  }

  /// Actualiza una fila local con el ID que nos da el servidor tras el éxito
  Future<void> markAsSynced(int localId, int serverId) async {
    final db = await dbHelper.database;
    await db.update(
      'transactions',
      {'server_id': serverId, 'is_synced': 1},
      where: 'id = ?',
      whereArgs: [localId],
    );
  }
}
