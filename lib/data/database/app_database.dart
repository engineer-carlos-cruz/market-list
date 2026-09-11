import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

const String databaseName = 'market_list.db';
const int schemaVersion = 1;

const String createProductsTable = '''
CREATE TABLE products (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  nombre TEXT NOT NULL,
  precio_unitario REAL NOT NULL,
  tienda TEXT NOT NULL,
  activo INTEGER NOT NULL DEFAULT 1
)''';

const String createShoppingListsTable = '''
CREATE TABLE shopping_lists (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  tienda TEXT NOT NULL,
  fecha TEXT NOT NULL
)''';

const String createShoppingListItemsTable = '''
CREATE TABLE shopping_list_items (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  id_lista INTEGER NOT NULL,
  id_producto INTEGER NOT NULL,
  cantidad INTEGER NOT NULL,
  FOREIGN KEY (id_lista) REFERENCES shopping_lists (id),
  FOREIGN KEY (id_producto) REFERENCES products (id)
)''';

const List<String> createTables = [
  createProductsTable,
  createShoppingListsTable,
  createShoppingListItemsTable,
];

class AppDatabase {
  AppDatabase._();

  static final AppDatabase instance = AppDatabase._();

  Database? _db;

  Future<Database> get database async {
    final path = join(await getDatabasesPath(), databaseName);
    return _db ??= await open(path);
  }

  Future<Database> open(String path) {
    return openDatabase(
      path,
      version: schemaVersion,
      onConfigure: _onConfigure,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future<void> _onCreate(Database db, int version) async {
    for (final statement in createTables) {
      await db.execute(statement);
    }
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    for (var version = oldVersion + 1; version <= newVersion; version++) {
      switch (version) {
        default:
          break;
      }
    }
  }
}