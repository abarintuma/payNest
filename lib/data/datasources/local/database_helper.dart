import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:path/path.dart';
import 'package:paynest/core/constants/app_constants.dart';

class DatabaseHelper {
  static Database? _database;
  static final DatabaseHelper instance = DatabaseHelper._init();

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    if (kIsWeb) {
      databaseFactory = databaseFactoryFfiWeb;
      return await databaseFactory.openDatabase(
        AppConstants.dbName,
        options: OpenDatabaseOptions(
          version: AppConstants.dbVersion,
          onCreate: _createDB,
          onUpgrade: _onUpgrade,
        ),
      );
    }

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, AppConstants.dbName);
    return await openDatabase(
      path,
      version: AppConstants.dbVersion,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE products (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT,
        category TEXT NOT NULL,
        price REAL NOT NULL,
        cost_price REAL,
        stock_quantity INTEGER NOT NULL DEFAULT 0,
        sku TEXT,
        barcode TEXT,
        image_url TEXT,
        is_active INTEGER NOT NULL DEFAULT 1,
        track_inventory INTEGER NOT NULL DEFAULT 1,
        tax_rate REAL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE customers (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        email TEXT,
        phone TEXT,
        address TEXT,
        total_spent REAL NOT NULL DEFAULT 0,
        total_orders INTEGER NOT NULL DEFAULT 0,
        notes TEXT,
        created_at TEXT NOT NULL,
        last_visit TEXT,
        loyalty_points REAL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE transactions (
        id TEXT PRIMARY KEY,
        receipt_number TEXT NOT NULL,
        items TEXT NOT NULL,
        subtotal REAL NOT NULL,
        tax_amount REAL NOT NULL,
        discount_amount REAL NOT NULL DEFAULT 0,
        total REAL NOT NULL,
        amount_paid REAL NOT NULL,
        change REAL NOT NULL DEFAULT 0,
        payment_method TEXT NOT NULL,
        status TEXT NOT NULL,
        type TEXT NOT NULL,
        customer_id TEXT,
        customer_name TEXT,
        notes TEXT,
        is_synced INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE categories (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        icon TEXT,
        color TEXT,
        product_count INTEGER DEFAULT 0
      )
    ''');

    // Seed default categories
    await db.insert('categories', {'id': 'all', 'name': 'All', 'icon': 'grid_view', 'color': '#6C63FF'});
    await db.insert('categories', {'id': 'food', 'name': 'Food', 'icon': 'restaurant', 'color': '#FF6584'});
    await db.insert('categories', {'id': 'beverages', 'name': 'Drinks', 'icon': 'local_cafe', 'color': '#00D2AA'});
    await db.insert('categories', {'id': 'electronics', 'name': 'Electronics', 'icon': 'devices', 'color': '#3DAEFF'});
    await db.insert('categories', {'id': 'clothing', 'name': 'Clothing', 'icon': 'checkroom', 'color': '#FFB547'});
    await db.insert('categories', {'id': 'other', 'name': 'Other', 'icon': 'more_horiz', 'color': '#94A3B8'});

    // Note: DevDataSeeder owns all initial product/customer/transaction data.
    // Do NOT seed placeholder data here — it creates duplicates and conflicts.
  }



  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Remove the original 8 placeholder products (p1-p8) that conflict with
      // the DevDataSeeder's full 125-product Uganda dataset.
      await db.delete('products', where: "id IN ('p1','p2','p3','p4','p5','p6','p7','p8')");
      // Also clear old placeholder customers (c1-c3) to avoid duplicates.
      await db.delete('customers', where: "id IN ('c1','c2','c3')");
    }
  }

  Future<void> closeDB() async {
    final db = await database;
    db.close();
    _database = null;
  }
}
