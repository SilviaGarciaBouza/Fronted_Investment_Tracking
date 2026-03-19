import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('invest_local.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 3,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future _createDB(Database db, int version) async {
    // Tabla de ajustes (IP)
    await db.execute(
      'CREATE TABLE settings (id INTEGER PRIMARY KEY, key TEXT, value TEXT)',
    );
    await db.insert('settings', {'key': 'server_ip', 'value': '10.0.2.2'});

    // Tabla de Usuarios (Para soportar varios perfiles en el móvil)
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY, 
        username TEXT,
        email TEXT,
        token TEXT
      )
    ''');

    // Tabla de Items (Añadido user_id para filtrar por usuario)
    await db.execute('''
      CREATE TABLE items (
        id INTEGER PRIMARY KEY,
        user_id INTEGER, 
        name TEXT,
        category_name TEXT,
        current_price REAL,
        stocks REAL,
        pnl_percent REAL,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    // Tabla de Transacciones
    await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY,
        item_id INTEGER,
        stocks REAL,
        purchase_price REAL,
        inv_eur REAL,
        purchase_date TEXT,
        FOREIGN KEY (item_id) REFERENCES items (id) ON DELETE CASCADE
      )
    ''');
    //Categorias
    await db.execute('''
  CREATE TABLE categories (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL
  )
''');
  }

  Future<void> saveUser(Map<String, dynamic> userData, String token) async {
    final db = await database;
    if (db != null) {
      await db.insert('users', {
        'id': userData['id'],
        'username': userData['username'],
        'email': userData['email'],
        'token': token,
      }, conflictAlgorithm: ConflictAlgorithm.replace);

      print("Usuario guardado en SQLite correctamente.");
    }
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 3) {
      await db.execute('DROP TABLE IF EXISTS transactions');
      await db.execute('DROP TABLE IF EXISTS items');
      await db.execute('DROP TABLE IF EXISTS users');
      await db.execute('DROP TABLE IF EXISTS settings');
      await _createDB(db, newVersion);
    }
  }
}
//TODO cerrar base de tados