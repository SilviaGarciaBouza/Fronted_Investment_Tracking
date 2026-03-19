import 'package:investment_tracking/database/database_helper.dart';
import 'package:sqflite/sqflite.dart';

import '../models/user.dart';

class UserDao {
  final dbHelper = DatabaseHelper.instance;

  Future<void> saveUser(User user) async {
    final db = await dbHelper.database;
    await db.insert('users', {
      'id': user.id,
      'username': user.username,
      'email': user.email,
      'token': user.token,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<User?> getUser() async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('users', limit: 1);

    if (maps.isNotEmpty) {
      return User.fromJson(maps.first);
    }
    return null;
  }

  Future<void> deleteUser() async {
    final db = await dbHelper.database;
    await db.delete('users');
  }
}
