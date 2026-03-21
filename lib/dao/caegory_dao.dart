import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../database/database_helper.dart';
import '../models/category.dart';

class CategoryDao {
  final dbHelper = DatabaseHelper.instance;

  Future<void> saveCategories(List<Category> categories) async {
    final db = await dbHelper.database;
    final batch = db.batch();
    for (var cat in categories) {
      batch.insert('categories', {
        'id': cat.id,
        'name': cat.name,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<List<Category>> getCategories() async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('categories');
    return maps.map((map) => Category.fromJson(map)).toList();
  }
}
