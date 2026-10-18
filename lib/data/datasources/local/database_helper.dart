import 'package:sqflite/sqflite.dart';
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
    final now = DateTime.now().toIso8601String();
    await db.insert('categories', {'id': 'all', 'name': 'All', 'icon': 'grid_view', 'color': '#6C63FF'});
    await db.insert('categories', {'id': 'food', 'name': 'Food', 'icon': 'restaurant', 'color': '#FF6584'});
    await db.insert('categories', {'id': 'beverages', 'name': 'Drinks', 'icon': 'local_cafe', 'color': '#00D2AA'});
    await db.insert('categories', {'id': 'electronics', 'name': 'Electronics', 'icon': 'devices', 'color': '#3DAEFF'});
    await db.insert('categories', {'id': 'clothing', 'name': 'Clothing', 'icon': 'checkroom', 'color': '#FFB547'});
    await db.insert('categories', {'id': 'other', 'name': 'Other', 'icon': 'more_horiz', 'color': '#94A3B8'});

    // Seed sample products
    await _seedSampleData(db);
  }

  Future<void> _seedSampleData(Database db) async {
    final now = DateTime.now().toIso8601String();
    final products = [
      {
        'id': 'p1', 'name': 'Espresso Shot', 'description': 'Rich Italian espresso', 'category': 'beverages',
        'price': 6000.0, 'cost_price': 2000.0, 'stock_quantity': 200, 'sku': 'BEV-001',
        'is_active': 1, 'track_inventory': 1, 'tax_rate': 18.0, 'created_at': now, 'updated_at': now,
      },
      {
        'id': 'p2', 'name': 'Cappuccino', 'description': 'Creamy steamed cappuccino', 'category': 'beverages',
        'price': 10000.0, 'cost_price': 3500.0, 'stock_quantity': 150, 'sku': 'BEV-002',
        'is_active': 1, 'track_inventory': 1, 'tax_rate': 18.0, 'created_at': now, 'updated_at': now,
      },
      {
        'id': 'p3', 'name': 'Chicken Rolex & Fries', 'description': 'Ugandan rolled chapati with spiced eggs and grilled chicken', 'category': 'food',
        'price': 15000.0, 'cost_price': 7000.0, 'stock_quantity': 50, 'sku': 'FOD-001',
        'is_active': 1, 'track_inventory': 1, 'tax_rate': 18.0, 'created_at': now, 'updated_at': now,
      },
      {
        'id': 'p4', 'name': 'Luwombo Special', 'description': 'Traditional steamed chicken stew in banana leaves', 'category': 'food',
        'price': 25000.0, 'cost_price': 12000.0, 'stock_quantity': 30, 'sku': 'FOD-002',
        'is_active': 1, 'track_inventory': 1, 'tax_rate': 18.0, 'created_at': now, 'updated_at': now,
      },
      {
        'id': 'p5', 'name': 'Wireless Earbuds', 'description': 'Bluetooth 5.0 earbuds with charging case', 'category': 'electronics',
        'price': 85000.0, 'cost_price': 45000.0, 'stock_quantity': 12, 'sku': 'ELC-001',
        'is_active': 1, 'track_inventory': 1, 'tax_rate': 18.0, 'created_at': now, 'updated_at': now,
      },
      {
        'id': 'p6', 'name': 'Fast Charge USB-C Cable', 'description': 'Braided durable 65W charging cable', 'category': 'electronics',
        'price': 25000.0, 'cost_price': 10000.0, 'stock_quantity': 45, 'sku': 'ELC-002',
        'is_active': 1, 'track_inventory': 1, 'tax_rate': 18.0, 'created_at': now, 'updated_at': now,
      },
      {
        'id': 'p7', 'name': 'Classic Cotton Polo', 'description': 'Premium 100% breathable cotton polo', 'category': 'clothing',
        'price': 45000.0, 'cost_price': 20000.0, 'stock_quantity': 25, 'sku': 'CLT-001',
        'is_active': 1, 'track_inventory': 1, 'tax_rate': 18.0, 'created_at': now, 'updated_at': now,
      },
      {
        'id': 'p8', 'name': 'Fresh Passion Fruit Juice', 'description': 'Chilled 500ml fresh natural juice', 'category': 'beverages',
        'price': 7000.0, 'cost_price': 2500.0, 'stock_quantity': 40, 'sku': 'BEV-003',
        'is_active': 1, 'track_inventory': 1, 'tax_rate': 18.0, 'created_at': now, 'updated_at': now,
      },
    ];

    for (final product in products) {
      await db.insert('products', product);
    }

    // Seed sample customers (Ugandan names & phone format)
    final customers = [
      {
        'id': 'c1', 'name': 'Kato Mukasa', 'email': 'kato.mukasa@example.com', 'phone': '+256772123456',
        'total_spent': 185000.0, 'total_orders': 8, 'created_at': now, 'loyalty_points': 185.0,
      },
      {
        'id': 'c2', 'name': 'Babirye Nakato', 'phone': '+256701234567',
        'total_spent': 340000.0, 'total_orders': 15, 'created_at': now, 'loyalty_points': 340.0,
      },
      {
        'id': 'c3', 'name': 'Ronald Okello', 'email': 'ronald.okello@example.com', 'phone': '+256782345678',
        'total_spent': 95000.0, 'total_orders': 4, 'created_at': now, 'loyalty_points': 95.0,
      },
    ];

    for (final customer in customers) {
      await db.insert('customers', customer);
    }
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Handle migrations here in the future
  }

  Future<void> closeDB() async {
    final db = await database;
    db.close();
    _database = null;
  }
}
