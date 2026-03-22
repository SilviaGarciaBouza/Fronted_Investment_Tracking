import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import '../models/category.dart';

/// Clase encargada del acceso a datos de las categorías en la base de datos local.
class CategoryDao {
  final dbHelper = DatabaseHelper.instance;

  /// Guarda una lista de categorías en la base de datos utilizando un proceso por lotes (batch).
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

  /// Recupera todas las categorías almacenadas localmente.
  Future<List<Category>> getCategories() async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('categories');
    return maps.map((map) => Category.fromJson(map)).toList();
  }
}
