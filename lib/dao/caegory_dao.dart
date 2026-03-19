import 'package:investment_tracking/database/database_helper.dart';

import '../models/category.dart';

class CategoryDao {
  final dbHelper = DatabaseHelper.instance;

  Future<void> synchronize(List<Category> categories) async {
    final db = await dbHelper.database;
    final batch = db.batch();

    batch.delete('categories');

    for (var cat in categories) {
      batch.insert('categories', {'id': cat.id, 'name': cat.name});
    }
    await batch.commit(noResult: true);
  }

  Future<List<Category>> getAll() async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('categories');

    return maps.map((map) => Category.fromJson(map)).toList();
  }
}
