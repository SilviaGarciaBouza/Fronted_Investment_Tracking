import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import '../models/category.dart';

/// Clase encargada del acceso a datos de las categorías en SQLite.
class CategoryDao {
  final dbHelper = DatabaseHelper.instance;

  /// Guarda una lista de categorías en la base de datos local.
  /// Si una categoría ya existe, reemplaza sus datos.
  Future<void> saveCategories(List<Category> categories) async {
    final db = await dbHelper.database;
    final batch = db.batch();
    for (var cat in categories) {
      batch.insert(
        'categories',
        cat.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  /// Recupera todas las categorías almacenadas localmente.
  Future<List<Category>> getCategories() async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('categories');
    return maps.map((map) => Category.fromJson(map)).toList();
  }

  /// Busca y devuelve una categoría específica mediante su ID local.
  /// Si no la encuentra, devuelve null.
  Future<Category?> getCategoryById(int id) async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'categories',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) return Category.fromJson(maps.first);
    return null;
  }
}
