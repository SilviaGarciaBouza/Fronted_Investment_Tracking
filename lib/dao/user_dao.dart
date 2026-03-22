import 'package:flutter/foundation.dart';
import 'package:investment_tracking/database/database_helper.dart';
import 'package:sqflite/sqflite.dart';
import '../models/user.dart';

/// Clase encargada de gestionar la sesión del usuario en la base de datos local.
class UserDao {
  final dbHelper = DatabaseHelper.instance;

  /// Guarda los datos del usuario y su token de sesión tras el login.
  Future<void> saveUser(User user) async {
    final db = await dbHelper.database;

    final List<Map<String, dynamic>> existing = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [user.id],
    );

    if (existing.isEmpty) {
      await db.insert('users', {
        'id': user.id,
        'username': user.username,
        'email': user.email,
        'token': user.token,
      });
    } else {
      await db.update(
        'users',
        {'username': user.username, 'email': user.email, 'token': user.token},
        where: 'id = ?',
        whereArgs: [user.id],
      );
    }
  }

  /// Recupera el usuario logueado actualmente, si existe.
  Future<User?> getUser() async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('users', limit: 1);

    if (maps.isNotEmpty) {
      return User.fromJson(maps.first);
    }
    return null;
  }

  /// Elimina el usuario almacenado en la base de datos local.
  ///
  /// Se utiliza para cerrar la sesión y limpiar el token JWT caducado.
  Future<void> deleteUser() async {
    final db = await DatabaseHelper.instance.database;
    try {
      await db.delete('users');
      debugPrint("Datos de usuario eliminados de SQLite correctamente.");
    } catch (e) {
      debugPrint("Error al eliminar usuario de SQLite: $e");
    }
  }
}
