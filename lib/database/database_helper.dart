import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';

///Crea si no existe la base de datos
class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('invest_tracking_v4.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 22,
      onConfigure: _onConfigure,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future _createDB(Database db, int version) async {
    await db.execute(
      'CREATE TABLE settings (id INTEGER PRIMARY KEY, key TEXT, value TEXT)',
    );
    await db.insert('settings', {'key': 'server_ip', 'value': '127.0.0.1'});

    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY, 
        username TEXT,
        email TEXT,
        token TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        server_id INTEGER,
        user_id INTEGER, 
        name TEXT,
        category_id INTEGER, -- CAMBIADO: Antes era category_name
        current_price REAL,
        is_synced INTEGER DEFAULT 0,
        is_deleted INTEGER DEFAULT 0,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
  CREATE TABLE transactions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    server_id INTEGER,
    item_id INTEGER,
    stocks REAL,
    purchase_price REAL,
    inv_eur REAL,
    purchase_date TEXT,
    is_synced INTEGER DEFAULT 0,
    is_deleted INTEGER DEFAULT 0, -- AÑADE ESTA LÍNEA
    FOREIGN KEY (item_id) REFERENCES items (id) ON DELETE CASCADE
  )
''');

    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL
      )
    ''');
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < newVersion) {
      await db.execute('DROP TABLE IF EXISTS transactions');
      await db.execute('DROP TABLE IF EXISTS items');
      await db.execute('DROP TABLE IF EXISTS categories');
      await db.execute('DROP TABLE IF EXISTS users');
      await db.execute('DROP TABLE IF EXISTS settings');
      await _createDB(db, newVersion);
    }
  }

  Future close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
