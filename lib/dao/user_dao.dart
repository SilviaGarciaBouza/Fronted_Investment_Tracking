import 'package:flutter/foundation.dart';
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

  /// Recupera la sesión actual para el AuthService.
  Future<User?> getUser() async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('users', limit: 1);
    if (maps.isNotEmpty) return User.fromJson(maps.first);
    return null;
  }

  /// Cierra la sesión eliminando los datos de SQLite.
  Future<void> deleteUser() async {
    final db = await dbHelper.database;
    await db.delete('users');
  }
}
