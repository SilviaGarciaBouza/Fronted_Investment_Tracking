import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import '../models/user.dart';

/// DAO para la gestión de la sesión local.
class UserDao {
  final dbHelper = DatabaseHelper.instance;

  /// Guarda o actualiza los datos del usuario y su token.
  Future<void> saveUser(User user) async {
    final db = await dbHelper.database;
    await db.insert('users', {
      'id': user.id,
      'username': user.username,
      'email': user.email,
      'token': user.token,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Recupera los datos de sesión de un usuario por su ID local.
  Future<User?> getUser(int userId) async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      limit: 1,
      where: 'id = ?',
      whereArgs: [userId],
    );
    if (maps.isNotEmpty) return User.fromJson(maps.first);
    return null;
  }
}
