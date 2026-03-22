import 'dart:io'; // Necesario para detectar la plataforma
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart'; // Solo se usará en escritorio
import 'package:path/path.dart';

/// Clase Singleton que gestiona el ciclo de vida de la base de datos local SQLite.
///
/// Se encarga de la creación de tablas, actualizaciones de versión y
/// compatibilidad entre plataformas móviles y de escritorio.
class DatabaseHelper {
  /// Instancia única (Singleton) de [DatabaseHelper].
  static final DatabaseHelper instance = DatabaseHelper._init();

  /// Almacena la conexión activa a la base de datos.
  static Database? _database;

  DatabaseHelper._init();

  /// Proporciona acceso a la base de datos, inicializándola si es la primera vez.
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('invest_local.db');
    return _database!;
  }

  /// Inicializa la conexión configurando el motor adecuado según la plataforma.
  Future<Database> _initDB(String filePath) async {
    // SOPORTE MULTIPLATAFORMA: Si es escritorio, inicializamos FFI
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 12,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  /// Crea la estructura de tablas inicial cuando se instala la aplicación.
  Future _createDB(Database db, int version) async {
    /// Tabla de configuración del sistema (ej. IP del servidor).
    await db.execute(
      'CREATE TABLE settings (id INTEGER PRIMARY KEY, key TEXT, value TEXT)',
    );
    await db.insert('settings', {'key': 'server_ip', 'value': '10.0.2.2'});

    /// Tabla de usuarios autenticados y sus tokens de sesión.
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY, 
        username TEXT,
        email TEXT,
        token TEXT
      )
    ''');

    /// Tabla de activos financieros (Items).
    await db.execute('''
      CREATE TABLE items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        server_id INTEGER,
        user_id INTEGER, 
        name TEXT,
        category_name TEXT,
        current_price REAL,
        is_synced INTEGER DEFAULT 0,
        is_deleted INTEGER DEFAULT 0,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    /// Tabla de transacciones individuales por activo.
    await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        item_id INTEGER,
        stocks REAL,
        purchase_price REAL,
        inv_eur REAL,
        purchase_date TEXT,
        FOREIGN KEY (item_id) REFERENCES items (id) ON DELETE CASCADE
      )
    ''');

    /// Tabla de categorías para organizar las inversiones.
    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL
      )
    ''');
  }

  /// Persiste los datos del usuario logueado en la base de datos local.
  Future<void> saveUser(Map<String, dynamic> userData, String token) async {
    final db = await database;
    await db.insert('users', {
      'id': userData['id'],
      'username': userData['username'],
      'email': userData['email'],
      'token': token,
    }, conflictAlgorithm: ConflictAlgorithm.replace);

    print("Usuario guardado en SQLite correctamente.");
  }

  /// Gestiona la migración de la base de datos cuando cambia la versión del esquema.
  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < newVersion) {
      await db.execute('DROP TABLE IF EXISTS categories');
      await db.execute('DROP TABLE IF EXISTS transactions');
      await db.execute('DROP TABLE IF EXISTS items');
      await db.execute('DROP TABLE IF EXISTS users');
      await db.execute('DROP TABLE IF EXISTS settings');
      await _createDB(db, newVersion);
    }
  }

  /// Cierra la conexión con la base de datos de forma segura.
  Future close() async {
    final db = await instance.database;
    db.close();
    _database = null;
  }
}
