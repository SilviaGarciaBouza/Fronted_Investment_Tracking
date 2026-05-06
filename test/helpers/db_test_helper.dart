import 'package:investment_tracking/database/database_helper.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart' hide Transaction;

/// Call in setUpAll to initialise FFI, enable WAL mode, and set a busy timeout
/// so concurrent test files can share the same SQLite file without lock errors.
Future<void> setUpDatabase() async {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  final db = await DatabaseHelper.instance.database;
  await db.execute('PRAGMA busy_timeout = 30000');
  await db.execute('PRAGMA journal_mode = WAL');
}

/// Call in tearDownAll to release the connection between test file runs.
Future<void> tearDownDatabase() => DatabaseHelper.instance.close();

/// Call in setUp / tearDown to guarantee a clean slate for every test.
Future<void> clearAllTables() async {
  final db = await DatabaseHelper.instance.database;
  await db.delete('transactions');
  await db.delete('items');
  await db.delete('categories');
  await db.delete('users');
}
