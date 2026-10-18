import 'package:sqflite/sqflite.dart' hide Transaction;
import 'package:paynest/data/models/models.dart';
import 'package:paynest/data/datasources/local/database_helper.dart';
import 'package:uuid/uuid.dart';

class ProductRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final _uuid = const Uuid();

  Future<List<Product>> getAllProducts({String? category, String? search}) async {
    final db = await _dbHelper.database;
    String where = 'is_active = 1';
    List<dynamic> whereArgs = [];

    if (category != null && category != 'all') {
      where += ' AND category = ?';
      whereArgs.add(category);
    }

    if (search != null && search.isNotEmpty) {
      where += ' AND (name LIKE ? OR sku LIKE ? OR barcode LIKE ?)';
      whereArgs.addAll(['%$search%', '%$search%', '%$search%']);
    }

    final maps = await db.query(
      'products',
      where: where,
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: 'name ASC',
    );

    return maps.map((m) => Product.fromMap(m)).toList();
  }

  Future<Product?> getProductById(String id) async {
    final db = await _dbHelper.database;
    final maps = await db.query('products', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Product.fromMap(maps.first);
  }

  Future<Product?> getProductByBarcode(String barcode) async {
    final db = await _dbHelper.database;
    final maps = await db.query('products', where: 'barcode = ?', whereArgs: [barcode]);
    if (maps.isEmpty) return null;
    return Product.fromMap(maps.first);
  }

  Future<String> addProduct(Product product) async {
    final db = await _dbHelper.database;
    final id = product.id.isEmpty ? _uuid.v4() : product.id;
    final newProduct = product.copyWith(id: id, createdAt: DateTime.now(), updatedAt: DateTime.now());
    await db.insert('products', newProduct.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    return id;
  }

  Future<void> saveProductFromRemote(Product product) async {
    final db = await _dbHelper.database;
    await db.insert('products', product.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateProduct(Product product) async {
    final db = await _dbHelper.database;
    await db.update(
      'products',
      product.copyWith(updatedAt: DateTime.now()).toMap(),
      where: 'id = ?',
      whereArgs: [product.id],
    );
  }

  Future<void> deleteProduct(String id) async {
    final db = await _dbHelper.database;
    await db.update(
      'products',
      {'is_active': 0, 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> updateStock(String productId, int quantityChange) async {
    final db = await _dbHelper.database;
    await db.rawUpdate(
      'UPDATE products SET stock_quantity = stock_quantity + ?, updated_at = ? WHERE id = ?',
      [quantityChange, DateTime.now().toIso8601String(), productId],
    );
  }

  Future<List<Product>> getLowStockProducts({int threshold = 10}) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'products',
      where: 'stock_quantity <= ? AND track_inventory = 1 AND is_active = 1',
      whereArgs: [threshold],
      orderBy: 'stock_quantity ASC',
    );
    return maps.map((m) => Product.fromMap(m)).toList();
  }

  Future<Map<String, int>> getCategoryCount() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      'SELECT category, COUNT(*) as count FROM products WHERE is_active = 1 GROUP BY category',
    );
    return {for (final row in result) row['category'] as String: row['count'] as int};
  }
}

class CustomerRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final _uuid = const Uuid();

  Future<List<Customer>> getAllCustomers({String? search}) async {
    final db = await _dbHelper.database;
    String? where;
    List<dynamic>? whereArgs;

    if (search != null && search.isNotEmpty) {
      where = 'name LIKE ? OR phone LIKE ? OR email LIKE ?';
      whereArgs = ['%$search%', '%$search%', '%$search%'];
    }

    final maps = await db.query(
      'customers',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'name ASC',
    );
    return maps.map((m) => Customer.fromMap(m)).toList();
  }

  Future<Customer?> getCustomerById(String id) async {
    final db = await _dbHelper.database;
    final maps = await db.query('customers', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Customer.fromMap(maps.first);
  }

  Future<String> addCustomer(Customer customer) async {
    final db = await _dbHelper.database;
    final id = customer.id.isEmpty ? _uuid.v4() : customer.id;
    final newCustomer = customer.copyWith(id: id, createdAt: DateTime.now());
    await db.insert('customers', newCustomer.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    return id;
  }

  Future<void> updateCustomer(Customer customer) async {
    final db = await _dbHelper.database;
    await db.update('customers', customer.toMap(), where: 'id = ?', whereArgs: [customer.id]);
  }

  Future<void> deleteCustomer(String id) async {
    final db = await _dbHelper.database;
    await db.delete('customers', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> updateCustomerStats(String customerId, double amount) async {
    final db = await _dbHelper.database;
    await db.rawUpdate(
      'UPDATE customers SET total_spent = total_spent + ?, total_orders = total_orders + 1, last_visit = ? WHERE id = ?',
      [amount, DateTime.now().toIso8601String(), customerId],
    );
  }

  Future<List<Customer>> getTopCustomers({int limit = 5}) async {
    final db = await _dbHelper.database;
    final maps = await db.query('customers', orderBy: 'total_spent DESC', limit: limit);
    return maps.map((m) => Customer.fromMap(m)).toList();
  }

  Future<void> saveCustomerFromRemote(Customer customer) async {
    final db = await _dbHelper.database;
    await db.insert('customers', customer.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }
}

class TransactionRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final _uuid = const Uuid();

  Future<List<Transaction>> getAllTransactions({
    DateTime? from,
    DateTime? to,
    String? status,
    String? paymentMethod,
  }) async {
    final db = await _dbHelper.database;
    String where = '1=1';
    List<dynamic> whereArgs = [];

    if (from != null) {
      where += ' AND created_at >= ?';
      whereArgs.add(from.toIso8601String());
    }
    if (to != null) {
      where += ' AND created_at <= ?';
      whereArgs.add(to.toIso8601String());
    }
    if (status != null) {
      where += ' AND status = ?';
      whereArgs.add(status);
    }
    if (paymentMethod != null) {
      where += ' AND payment_method = ?';
      whereArgs.add(paymentMethod);
    }

    final maps = await db.query(
      'transactions',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'created_at DESC',
    );
    return maps.map((m) => Transaction.fromMap(m)).toList();
  }

  Future<Transaction?> getTransactionById(String id) async {
    final db = await _dbHelper.database;
    final maps = await db.query('transactions', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Transaction.fromMap(maps.first);
  }

  Future<String> addTransaction(Transaction transaction) async {
    final db = await _dbHelper.database;
    final id = transaction.id.isEmpty ? _uuid.v4() : transaction.id;
    final newTxn = Transaction(
      id: id,
      receiptNumber: transaction.receiptNumber,
      items: transaction.items,
      subtotal: transaction.subtotal,
      taxAmount: transaction.taxAmount,
      discountAmount: transaction.discountAmount,
      total: transaction.total,
      amountPaid: transaction.amountPaid,
      change: transaction.change,
      paymentMethod: transaction.paymentMethod,
      status: transaction.status,
      type: transaction.type,
      customerId: transaction.customerId,
      customerName: transaction.customerName,
      notes: transaction.notes,
      isSynced: transaction.isSynced,
      createdAt: transaction.createdAt,
    );
    await db.insert('transactions', newTxn.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    return id;
  }

  Future<void> updateTransactionStatus(String id, String status) async {
    final db = await _dbHelper.database;
    await db.update('transactions', {'status': status}, where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Transaction>> getUnsyncedTransactions() async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'transactions',
      where: 'is_synced = 0',
      orderBy: 'created_at ASC',
    );
    return maps.map((m) => Transaction.fromMap(m)).toList();
  }

  Future<void> markAsSynced(String id) async {
    final db = await _dbHelper.database;
    await db.update(
      'transactions',
      {'is_synced': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<Map<String, dynamic>> getDailySummary(DateTime date) async {
    final db = await _dbHelper.database;
    final startOfDay = DateTime(date.year, date.month, date.day).toIso8601String();
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59).toIso8601String();

    final result = await db.rawQuery('''
      SELECT 
        COUNT(*) as count,
        SUM(total) as revenue,
        SUM(tax_amount) as tax,
        SUM(discount_amount) as discount,
        payment_method
      FROM transactions
      WHERE created_at BETWEEN ? AND ? AND status = 'COMPLETED' AND type = 'SALE'
      GROUP BY payment_method
    ''', [startOfDay, endOfDay]);

    double totalRevenue = 0;
    int totalCount = 0;
    final paymentBreakdown = <String, double>{};

    for (final row in result) {
      totalRevenue += (row['revenue'] as num?)?.toDouble() ?? 0;
      totalCount += (row['count'] as int?) ?? 0;
      paymentBreakdown[row['payment_method'] as String] =
          (row['revenue'] as num?)?.toDouble() ?? 0;
    }

    return {
      'totalRevenue': totalRevenue,
      'totalCount': totalCount,
      'paymentBreakdown': paymentBreakdown,
    };
  }

  Future<List<Map<String, dynamic>>> getWeeklySales() async {
    final db = await _dbHelper.database;
    final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7)).toIso8601String();
    return await db.rawQuery('''
      SELECT 
        DATE(created_at) as date,
        SUM(total) as revenue,
        COUNT(*) as count
      FROM transactions
      WHERE created_at >= ? AND status = 'COMPLETED' AND type = 'SALE'
      GROUP BY DATE(created_at)
      ORDER BY date ASC
    ''', [sevenDaysAgo]);
  }

  Future<Map<String, dynamic>> getRevenueStats() async {
    final db = await _dbHelper.database;
    final today = DateTime.now();
    final startOfToday = DateTime(today.year, today.month, today.day).toIso8601String();
    final startOfMonth = DateTime(today.year, today.month, 1).toIso8601String();

    final todayResult = await db.rawQuery('''
      SELECT SUM(total) as revenue, COUNT(*) as count
      FROM transactions WHERE created_at >= ? AND status = 'COMPLETED' AND type = 'SALE'
    ''', [startOfToday]);

    final monthResult = await db.rawQuery('''
      SELECT SUM(total) as revenue, COUNT(*) as count
      FROM transactions WHERE created_at >= ? AND status = 'COMPLETED' AND type = 'SALE'
    ''', [startOfMonth]);

    final totalResult = await db.rawQuery('''
      SELECT SUM(total) as revenue, COUNT(*) as count
      FROM transactions WHERE status = 'COMPLETED' AND type = 'SALE'
    ''');

    return {
      'todayRevenue': (todayResult.first['revenue'] as num?)?.toDouble() ?? 0,
      'todayCount': (todayResult.first['count'] as int?) ?? 0,
      'monthRevenue': (monthResult.first['revenue'] as num?)?.toDouble() ?? 0,
      'monthCount': (monthResult.first['count'] as int?) ?? 0,
      'totalRevenue': (totalResult.first['revenue'] as num?)?.toDouble() ?? 0,
      'totalCount': (totalResult.first['count'] as int?) ?? 0,
    };
  }
}
