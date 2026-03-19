import 'package:investment_tracking/database/database_helper.dart';

import '../models/item.dart';

class ItemDao {
  final dbHelper = DatabaseHelper.instance;

  Future<void> synchronizeItems(List<Item> items, int userId) async {
    final db = await dbHelper.database;
    final batch = db.batch();

    batch.delete('items', where: 'user_id = ?', whereArgs: [userId]);

    for (var item in items) {
      batch.insert('items', {
        'id': item.id,
        'user_id': userId,
        'name': item.name,
        'category_name': item.category.name,
        'current_price': item.currentPrice,
        'stocks': item.stocks,
        'pnl_percent': item.nRPlPercentaje,
      });
    }
    await batch.commit(noResult: true);
  }

  Future<List<Item>> getItemsForUser(int userId) async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'items',
      where: 'user_id = ?',
      whereArgs: [userId],
    );

    return List.generate(maps.length, (i) {
      return Item.fromLocalMap(maps[i]);
    });
  }
}
