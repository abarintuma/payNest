import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:paynest/core/constants/app_constants.dart';
import 'package:paynest/data/datasources/local/database_helper.dart';

/// Safe, idempotent, development-only data seeder for PayNest.
/// Seeds Uganda-specific products, categories, customers, and historical sales.
///
/// Safety guarantees:
/// 1. Uses explicit `seed_*` ID prefixes.
/// 2. Idempotent: Can be run multiple times without duplicating data.
/// 3. Does not touch or overwrite real user data.
/// 4. Does not trigger secondary stock deductions.
/// 5. Marks sales as `is_synced: 1` to prevent polluting live cloud databases.
class DevDataSeeder {
  static final DevDataSeeder instance = DevDataSeeder._();
  DevDataSeeder._();

  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  /// Check whether development seed data is already loaded
  Future<bool> isSeeded() async {
    try {
      final db = await _dbHelper.database;
      final result = await db.rawQuery(
        "SELECT COUNT(*) as count FROM products WHERE id LIKE 'seed_p_%'",
      );
      final count = (result.first['count'] as int?) ?? 0;
      return count > 0;
    } catch (e) {
      debugPrint('[DevDataSeeder] Error checking seed state: $e');
      return false;
    }
  }

  /// Populate the local SQLite database with realistic Uganda POS sample data
  Future<void> seedAll({bool force = false}) async {
    final db = await _dbHelper.database;

    if (!force && await isSeeded()) {
      debugPrint('[DevDataSeeder] Database already populated with sample data. Skipping.');
      return;
    }

    debugPrint('[DevDataSeeder] Seeding realistic Uganda POS dataset...');

    await db.transaction((txn) async {
      await _seedCategories(txn);
      await _seedProducts(txn);
      await _seedCustomers(txn);
      await _seedTransactions(txn);
    });

    debugPrint('[DevDataSeeder] Dataset successfully seeded.');
  }

  Future<void> _seedCategories(Transaction txn) async {
    final categories = [
      {'id': 'all', 'name': 'All', 'icon': 'grid_view', 'color': '#6C63FF'},
      {'id': 'food', 'name': 'Food & Meals', 'icon': 'restaurant', 'color': '#FF6584'},
      {'id': 'beverages', 'name': 'Drinks & Coffee', 'icon': 'local_cafe', 'color': '#00D2AA'},
      {'id': 'groceries', 'name': 'Groceries', 'icon': 'shopping_basket', 'color': '#10B981'},
      {'id': 'electronics', 'name': 'Electronics', 'icon': 'devices', 'color': '#3DAEFF'},
      {'id': 'clothing', 'name': 'Clothing', 'icon': 'checkroom', 'color': '#FFB547'},
      {'id': 'services', 'name': 'Services', 'icon': 'design_services', 'color': '#8B5CF6'},
      {'id': 'other', 'name': 'Other', 'icon': 'more_horiz', 'color': '#94A3B8'},
    ];

    for (final cat in categories) {
      await txn.insert(
        'categories',
        cat,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  Future<void> _seedProducts(Transaction txn) async {
    final now = DateTime.now();
    final todayIso = now.toIso8601String();

    final products = [
      // --- Food ---
      {
        'id': 'seed_p_rolex',
        'name': 'Chicken Rolex & Fries',
        'description': 'Warm rolled Ugandan chapati with 2 eggs, spiced chicken, onions and tomatoes',
        'category': 'food',
        'price': 15000.0,
        'cost_price': 7000.0,
        'stock_quantity': 45,
        'sku': 'FOD-RLX-01',
        'barcode': '600100100001',
        'is_active': 1,
        'track_inventory': 1,
        'tax_rate': 18.0,
        'created_at': todayIso,
        'updated_at': todayIso,
      },
      {
        'id': 'seed_p_luwombo',
        'name': 'Luwombo Beef & Matooke',
        'description': 'Traditional slow-steamed beef stew in banana leaves served with mashed matooke',
        'category': 'food',
        'price': 28000.0,
        'cost_price': 14000.0,
        'stock_quantity': 25,
        'sku': 'FOD-LWM-02',
        'barcode': '600100100002',
        'is_active': 1,
        'track_inventory': 1,
        'tax_rate': 18.0,
        'created_at': todayIso,
        'updated_at': todayIso,
      },
      {
        'id': 'seed_p_tilapia',
        'name': 'Crispy Whole Tilapia with Gonja',
        'description': 'Fried Lake Victoria tilapia served with roasted sweet plantain (gonja) and kachumbari',
        'category': 'food',
        'price': 35000.0,
        'cost_price': 19000.0,
        'stock_quantity': 18,
        'sku': 'FOD-TLP-03',
        'barcode': '600100100003',
        'is_active': 1,
        'track_inventory': 1,
        'tax_rate': 18.0,
        'created_at': todayIso,
        'updated_at': todayIso,
      },
      {
        'id': 'seed_p_katogo',
        'name': 'Katogo Breakfast Special',
        'description': 'Matooke stewed with tender beef offals, cow peas, and rich local herb gravy',
        'category': 'food',
        'price': 12000.0,
        'cost_price': 5500.0,
        'stock_quantity': 35,
        'sku': 'FOD-KTG-04',
        'barcode': '600100100004',
        'is_active': 1,
        'track_inventory': 1,
        'tax_rate': 18.0,
        'created_at': todayIso,
        'updated_at': todayIso,
      },
      {
        'id': 'seed_p_samosa',
        'name': 'Beef Samosa Platter (Pack of 6)',
        'description': 'Golden fried crispy triangular pastries with spiced minced beef filling',
        'category': 'food',
        'price': 10000.0,
        'cost_price': 4000.0,
        'stock_quantity': 50,
        'sku': 'FOD-SMS-05',
        'barcode': '600100100005',
        'is_active': 1,
        'track_inventory': 1,
        'tax_rate': 18.0,
        'created_at': todayIso,
        'updated_at': todayIso,
      },

      // --- Beverages ---
      {
        'id': 'seed_p_espresso',
        'name': 'Single Espresso (Mount Elgon Arabica)',
        'description': 'Rich dark roast espresso pulled from premium Ugandan Bugisu Arabica beans',
        'category': 'beverages',
        'price': 6000.0,
        'cost_price': 1800.0,
        'stock_quantity': 200,
        'sku': 'BEV-ESP-01',
        'barcode': '600100200001',
        'is_active': 1,
        'track_inventory': 1,
        'tax_rate': 18.0,
        'created_at': todayIso,
        'updated_at': todayIso,
      },
      {
        'id': 'seed_p_cappuccino',
        'name': 'Steamed Cappuccino',
        'description': 'Espresso with silky microfoam and a dust of Belgian cocoa powder',
        'category': 'beverages',
        'price': 10000.0,
        'cost_price': 3500.0,
        'stock_quantity': 140,
        'sku': 'BEV-CAP-02',
        'barcode': '600100200002',
        'is_active': 1,
        'track_inventory': 1,
        'tax_rate': 18.0,
        'created_at': todayIso,
        'updated_at': todayIso,
      },
      {
        'id': 'seed_p_passion_juice',
        'name': 'Fresh Masaka Passion Fruit Juice (500ml)',
        'description': '100% natural chilled passion fruit pulp sweetened with organic cane sugar',
        'category': 'beverages',
        'price': 7000.0,
        'cost_price': 2500.0,
        'stock_quantity': 55,
        'sku': 'BEV-PAS-03',
        'barcode': '600100200003',
        'is_active': 1,
        'track_inventory': 1,
        'tax_rate': 18.0,
        'created_at': todayIso,
        'updated_at': todayIso,
      },
      {
        'id': 'seed_p_water',
        'name': 'Rwenzori Natural Mineral Water (500ml)',
        'description': 'Pure bottled spring water from Mount Rwenzori',
        'category': 'beverages',
        'price': 2000.0,
        'cost_price': 800.0,
        'stock_quantity': 300,
        'sku': 'BEV-WTR-04',
        'barcode': '600100200004',
        'is_active': 1,
        'track_inventory': 1,
        'tax_rate': 18.0,
        'created_at': todayIso,
        'updated_at': todayIso,
      },
      {
        'id': 'seed_p_stoney',
        'name': 'Stoney Tangawisi Ginger Beer (330ml Can)',
        'description': 'Spicy fizzy ginger soda popular across East Africa',
        'category': 'beverages',
        'price': 3000.0,
        'cost_price': 1500.0,
        'stock_quantity': 110,
        'sku': 'BEV-STN-05',
        'barcode': '600100200005',
        'is_active': 1,
        'track_inventory': 1,
        'tax_rate': 18.0,
        'created_at': todayIso,
        'updated_at': todayIso,
      },

      // --- Groceries & Essentials ---
      {
        'id': 'seed_p_sugar',
        'name': 'Kakira Pure White Sugar (1kg)',
        'description': 'Locally milled premium granulated white cane sugar from Kakira Sugar Works',
        'category': 'groceries',
        'price': 6000.0,
        'cost_price': 4200.0,
        'stock_quantity': 80,
        'sku': 'GRO-SGR-01',
        'barcode': '600100300001',
        'is_active': 1,
        'track_inventory': 1,
        'tax_rate': 18.0,
        'created_at': todayIso,
        'updated_at': todayIso,
      },
      {
        'id': 'seed_p_oil',
        'name': 'Mukwano Cooking Oil (1 Litre)',
        'description': 'Fortified triple-refined vegetable cooking oil with Vitamin A',
        'category': 'groceries',
        'price': 11500.0,
        'cost_price': 8500.0,
        'stock_quantity': 45,
        'sku': 'GRO-OIL-02',
        'barcode': '600100300002',
        'is_active': 1,
        'track_inventory': 1,
        'tax_rate': 18.0,
        'created_at': todayIso,
        'updated_at': todayIso,
      },
      {
        'id': 'seed_p_flour',
        'name': 'Supreme Bakers Flour (2kg Pack)',
        'description': 'High-gluten white wheat flour suitable for chapatis and bread',
        'category': 'groceries',
        'price': 9500.0,
        'cost_price': 6800.0,
        'stock_quantity': 30,
        'sku': 'GRO-FLR-03',
        'barcode': '600100300003',
        'is_active': 1,
        'track_inventory': 1,
        'tax_rate': 18.0,
        'created_at': todayIso,
        'updated_at': todayIso,
      },

      // --- Electronics ---
      {
        'id': 'seed_p_powerbank',
        'name': 'Oraimo 10,000mAh Dual Output Power Bank',
        'description': 'Slim portable charger with fast charging and multi-protect safety system',
        'category': 'electronics',
        'price': 75000.0,
        'cost_price': 45000.0,
        'stock_quantity': 16,
        'sku': 'ELC-PWB-01',
        'barcode': '600100400001',
        'is_active': 1,
        'track_inventory': 1,
        'tax_rate': 18.0,
        'created_at': todayIso,
        'updated_at': todayIso,
      },
      {
        'id': 'seed_p_earbuds',
        'name': 'Wireless Bluetooth Earbuds with Charging Case',
        'description': 'True wireless stereo earbuds with touch control and deep bass',
        'category': 'electronics',
        'price': 85000.0,
        'cost_price': 48000.0,
        'stock_quantity': 7, // Low stock item (< 10) for testing low-stock alerts
        'sku': 'ELC-EBD-02',
        'barcode': '600100400002',
        'is_active': 1,
        'track_inventory': 1,
        'tax_rate': 18.0,
        'created_at': todayIso,
        'updated_at': todayIso,
      },
      {
        'id': 'seed_p_cable',
        'name': 'Braided Type-C to Type-C 65W Fast Cable',
        'description': '2-meter heavy-duty nylon braided cable supporting fast charge and data sync',
        'category': 'electronics',
        'price': 25000.0,
        'cost_price': 10000.0,
        'stock_quantity': 38,
        'sku': 'ELC-CBL-03',
        'barcode': '600100400003',
        'is_active': 1,
        'track_inventory': 1,
        'tax_rate': 18.0,
        'created_at': todayIso,
        'updated_at': todayIso,
      },
      {
        'id': 'seed_p_charger',
        'name': 'Samsung 25W Super Fast Wall Charger',
        'description': 'Adaptive wall adapter with Power Delivery 3.0 technology',
        'category': 'electronics',
        'price': 55000.0,
        'cost_price': 30000.0,
        'stock_quantity': 0, // Out of stock item for testing stockout alerts
        'sku': 'ELC-CHG-04',
        'barcode': '600100400004',
        'is_active': 1,
        'track_inventory': 1,
        'tax_rate': 18.0,
        'created_at': todayIso,
        'updated_at': todayIso,
      },

      // --- Clothing ---
      {
        'id': 'seed_p_kitenge',
        'name': 'Modern Kitenge African Print Shirt',
        'description': 'Tailored authentic East African wax cotton shirt in vibrant geometric prints',
        'category': 'clothing',
        'price': 65000.0,
        'cost_price': 32000.0,
        'stock_quantity': 14,
        'sku': 'CLT-KTG-01',
        'barcode': '600100500001',
        'is_active': 1,
        'track_inventory': 1,
        'tax_rate': 18.0,
        'created_at': todayIso,
        'updated_at': todayIso,
      },
      {
        'id': 'seed_p_polo',
        'name': 'Breathable Cotton Pique Polo',
        'description': 'Classic regular fit polo shirt crafted from 100% pre-shrunk cotton',
        'category': 'clothing',
        'price': 45000.0,
        'cost_price': 22000.0,
        'stock_quantity': 26,
        'sku': 'CLT-PLO-02',
        'barcode': '600100500002',
        'is_active': 1,
        'track_inventory': 1,
        'tax_rate': 18.0,
        'created_at': todayIso,
        'updated_at': todayIso,
      },
    ];

    for (final prod in products) {
      await txn.insert(
        'products',
        prod,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  Future<void> _seedCustomers(Transaction txn) async {
    final now = DateTime.now();

    // Customer purchase totals will be updated consistently after transactions are seeded
    final customers = [
      {
        'id': 'seed_c_mukasa',
        'name': 'Kato Mukasa',
        'email': 'kato.mukasa@kampala.ug',
        'phone': '+256772123456',
        'address': 'Plot 42, Kampala Road, Central Division',
        'total_spent': 0.0,
        'total_orders': 0,
        'notes': 'Loyal corporate client; prefers MTN MoMo payment receipts via email',
        'created_at': now.subtract(const Duration(days: 30)).toIso8601String(),
        'last_visit': now.toIso8601String(),
        'loyalty_points': 0.0,
      },
      {
        'id': 'seed_c_nakato',
        'name': 'Babirye Nakato',
        'email': 'babirye.n@gmail.com',
        'phone': '+256701234567',
        'address': 'Ntinda Complex, Block B, Nakawa',
        'total_spent': 0.0,
        'total_orders': 0,
        'notes': 'Frequent lunch diner; orders catering specials',
        'created_at': now.subtract(const Duration(days: 45)).toIso8601String(),
        'last_visit': now.subtract(const Duration(days: 1)).toIso8601String(),
        'loyalty_points': 0.0,
      },
      {
        'id': 'seed_c_okello',
        'name': 'Ronald Okello',
        'email': 'ronald.okello@business.co.ug',
        'phone': '+256782345678',
        'address': 'Village Mall, Bugolobi',
        'total_spent': 0.0,
        'total_orders': 0,
        'notes': 'Wholesale grocery & electronics buyer',
        'created_at': now.subtract(const Duration(days: 60)).toIso8601String(),
        'last_visit': now.subtract(const Duration(days: 3)).toIso8601String(),
        'loyalty_points': 0.0,
      },
      {
        'id': 'seed_c_ainembabazi',
        'name': 'Grace Ainembabazi',
        'email': 'grace.aine@outlook.ug',
        'phone': '+256752987654',
        'address': 'Acacia Avenue, Kololo',
        'total_spent': 0.0,
        'total_orders': 0,
        'notes': 'Purchases kitenge shirts and specialty coffee',
        'created_at': now.subtract(const Duration(days: 20)).toIso8601String(),
        'last_visit': now.subtract(const Duration(days: 2)).toIso8601String(),
        'loyalty_points': 0.0,
      },
      {
        'id': 'seed_c_wasswa',
        'name': 'David Wasswa',
        'email': 'david.wasswa@entebbe.org',
        'phone': '+256774556677',
        'address': 'Airport Road, Entebbe Municipality',
        'total_spent': 0.0,
        'total_orders': 0,
        'notes': 'Travels frequently; prefers Airtel Money or Visa Card',
        'created_at': now.subtract(const Duration(days: 15)).toIso8601String(),
        'last_visit': now.subtract(const Duration(days: 4)).toIso8601String(),
        'loyalty_points': 0.0,
      },
    ];

    for (final cust in customers) {
      await txn.insert(
        'customers',
        cust,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  Future<void> _seedTransactions(Transaction txn) async {
    final now = DateTime.now();

    // Helper to calculate exact tax, subtotal, and total consistent with AppConstants and CartProvider
    Map<String, dynamic> createTxnRecord({
      required String id,
      required String receiptNumber,
      required DateTime date,
      required String paymentMethod,
      required List<Map<String, dynamic>> items,
      String? customerId,
      String? customerName,
      double discountPercent = 0.0,
      double? cashAmountPaid,
    }) {
      double subtotal = 0.0;
      for (final item in items) {
        final price = (item['price'] as num).toDouble();
        final qty = item['quantity'] as int;
        subtotal += price * qty;
      }

      final discountAmount = subtotal * (discountPercent / 100);
      final taxableAmount = subtotal - discountAmount;
      // Uganda 18% VAT
      final taxAmount = taxableAmount * 0.18;
      final total = taxableAmount + taxAmount;

      final amountPaid = cashAmountPaid ?? total;
      final change = (amountPaid > total) ? (amountPaid - total) : 0.0;

      return {
        'id': id,
        'receipt_number': receiptNumber,
        'items': jsonEncode(items),
        'subtotal': subtotal,
        'tax_amount': taxAmount,
        'discount_amount': discountAmount,
        'total': total,
        'amount_paid': amountPaid,
        'change': change,
        'payment_method': paymentMethod,
        'status': AppConstants.statusCompleted,
        'type': AppConstants.transactionSale,
        'customer_id': customerId,
        'customer_name': customerName,
        'notes': 'Sample development transaction (demo data)',
        'is_synced': 1, // Marked synced so it does not send demo sales to real Firestore
        'created_at': date.toIso8601String(),
      };
    }

    // Historical transactions spanning the past 7 days to fully populate charts, daily summary and revenue stats
    final txnData = [
      // --- Today ---
      createTxnRecord(
        id: 'seed_txn_001',
        receiptNumber: 'RCP-DEMO-1001',
        date: now.subtract(const Duration(hours: 2)),
        paymentMethod: AppConstants.paymentMtnMomo,
        customerId: 'seed_c_mukasa',
        customerName: 'Kato Mukasa',
        items: [
          {'product_id': 'seed_p_rolex', 'product_name': 'Chicken Rolex & Fries', 'price': 15000.0, 'quantity': 2},
          {'product_id': 'seed_p_passion_juice', 'product_name': 'Fresh Masaka Passion Fruit Juice', 'price': 7000.0, 'quantity': 2},
        ],
      ),
      createTxnRecord(
        id: 'seed_txn_002',
        receiptNumber: 'RCP-DEMO-1002',
        date: now.subtract(const Duration(hours: 4)),
        paymentMethod: AppConstants.paymentCash,
        customerId: null,
        customerName: 'Walk-in Customer',
        cashAmountPaid: 50000.0,
        items: [
          {'product_id': 'seed_p_tilapia', 'product_name': 'Crispy Whole Tilapia with Gonja', 'price': 35000.0, 'quantity': 1},
          {'product_id': 'seed_p_stoney', 'product_name': 'Stoney Tangawisi Ginger Beer', 'price': 3000.0, 'quantity': 2},
        ],
      ),
      createTxnRecord(
        id: 'seed_txn_003',
        receiptNumber: 'RCP-DEMO-1003',
        date: now.subtract(const Duration(hours: 6)),
        paymentMethod: AppConstants.paymentAirtelMoney,
        customerId: 'seed_c_nakato',
        customerName: 'Babirye Nakato',
        items: [
          {'product_id': 'seed_p_cappuccino', 'product_name': 'Steamed Cappuccino', 'price': 10000.0, 'quantity': 2},
          {'product_id': 'seed_p_samosa', 'product_name': 'Beef Samosa Platter (Pack of 6)', 'price': 10000.0, 'quantity': 1},
        ],
      ),

      // --- Yesterday ---
      createTxnRecord(
        id: 'seed_txn_004',
        receiptNumber: 'RCP-DEMO-1004',
        date: now.subtract(const Duration(days: 1, hours: 3)),
        paymentMethod: AppConstants.paymentCard,
        customerId: 'seed_c_ainembabazi',
        customerName: 'Grace Ainembabazi',
        items: [
          {'product_id': 'seed_p_kitenge', 'product_name': 'Modern Kitenge African Print Shirt', 'price': 65000.0, 'quantity': 1},
          {'product_id': 'seed_p_espresso', 'product_name': 'Single Espresso', 'price': 6000.0, 'quantity': 1},
        ],
      ),
      createTxnRecord(
        id: 'seed_txn_005',
        receiptNumber: 'RCP-DEMO-1005',
        date: now.subtract(const Duration(days: 1, hours: 5)),
        paymentMethod: AppConstants.paymentMtnMomo,
        customerId: 'seed_c_okello',
        customerName: 'Ronald Okello',
        discountPercent: 5.0, // 5% discount
        items: [
          {'product_id': 'seed_p_oil', 'product_name': 'Mukwano Cooking Oil (1L)', 'price': 11500.0, 'quantity': 4},
          {'product_id': 'seed_p_sugar', 'product_name': 'Kakira Pure White Sugar (1kg)', 'price': 6000.0, 'quantity': 5},
        ],
      ),

      // --- 2 Days Ago ---
      createTxnRecord(
        id: 'seed_txn_006',
        receiptNumber: 'RCP-DEMO-1006',
        date: now.subtract(const Duration(days: 2, hours: 2)),
        paymentMethod: AppConstants.paymentBank,
        customerId: 'seed_c_okello',
        customerName: 'Ronald Okello',
        items: [
          {'product_id': 'seed_p_powerbank', 'product_name': 'Oraimo 10,000mAh Power Bank', 'price': 75000.0, 'quantity': 2},
          {'product_id': 'seed_p_cable', 'product_name': 'Braided Type-C Fast Cable', 'price': 25000.0, 'quantity': 3},
        ],
      ),
      createTxnRecord(
        id: 'seed_txn_007',
        receiptNumber: 'RCP-DEMO-1007',
        date: now.subtract(const Duration(days: 2, hours: 6)),
        paymentMethod: AppConstants.paymentCash,
        cashAmountPaid: 40000.0,
        items: [
          {'product_id': 'seed_p_luwombo', 'product_name': 'Luwombo Beef & Matooke', 'price': 28000.0, 'quantity': 1},
          {'product_id': 'seed_p_water', 'product_name': 'Rwenzori Mineral Water', 'price': 2000.0, 'quantity': 2},
        ],
      ),

      // --- 3 Days Ago ---
      createTxnRecord(
        id: 'seed_txn_008',
        receiptNumber: 'RCP-DEMO-1008',
        date: now.subtract(const Duration(days: 3, hours: 4)),
        paymentMethod: AppConstants.paymentMtnMomo,
        customerId: 'seed_c_mukasa',
        customerName: 'Kato Mukasa',
        items: [
          {'product_id': 'seed_p_polo', 'product_name': 'Breathable Cotton Pique Polo', 'price': 45000.0, 'quantity': 1},
          {'product_id': 'seed_p_espresso', 'product_name': 'Single Espresso', 'price': 6000.0, 'quantity': 2},
        ],
      ),

      // --- 4 Days Ago ---
      createTxnRecord(
        id: 'seed_txn_009',
        receiptNumber: 'RCP-DEMO-1009',
        date: now.subtract(const Duration(days: 4, hours: 1)),
        paymentMethod: AppConstants.paymentAirtelMoney,
        customerId: 'seed_c_wasswa',
        customerName: 'David Wasswa',
        items: [
          {'product_id': 'seed_p_earbuds', 'product_name': 'Wireless Bluetooth Earbuds', 'price': 85000.0, 'quantity': 1},
          {'product_id': 'seed_p_cable', 'product_name': 'Braided Type-C Fast Cable', 'price': 25000.0, 'quantity': 1},
        ],
      ),

      // --- 5 Days Ago ---
      createTxnRecord(
        id: 'seed_txn_010',
        receiptNumber: 'RCP-DEMO-1010',
        date: now.subtract(const Duration(days: 5, hours: 5)),
        paymentMethod: AppConstants.paymentCash,
        cashAmountPaid: 60000.0,
        items: [
          {'product_id': 'seed_p_katogo', 'product_name': 'Katogo Breakfast Special', 'price': 12000.0, 'quantity': 3},
          {'product_id': 'seed_p_passion_juice', 'product_name': 'Fresh Masaka Passion Fruit Juice', 'price': 7000.0, 'quantity': 2},
        ],
      ),

      // --- 6 Days Ago ---
      createTxnRecord(
        id: 'seed_txn_011',
        receiptNumber: 'RCP-DEMO-1011',
        date: now.subtract(const Duration(days: 6, hours: 3)),
        paymentMethod: AppConstants.paymentMtnMomo,
        customerId: 'seed_c_nakato',
        customerName: 'Babirye Nakato',
        items: [
          {'product_id': 'seed_p_rolex', 'product_name': 'Chicken Rolex & Fries', 'price': 15000.0, 'quantity': 3},
          {'product_id': 'seed_p_cappuccino', 'product_name': 'Steamed Cappuccino', 'price': 10000.0, 'quantity': 3},
        ],
      ),
    ];

    // Track aggregates for customers to maintain total internal consistency
    final customerTotals = <String, double>{};
    final customerCounts = <String, int>{};
    final customerLastVisit = <String, DateTime>{};

    for (final row in txnData) {
      await txn.insert(
        'transactions',
        row,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      final cId = row['customer_id'] as String?;
      if (cId != null && cId.isNotEmpty) {
        final total = row['total'] as double;
        final date = DateTime.parse(row['created_at'] as String);

        customerTotals[cId] = (customerTotals[cId] ?? 0.0) + total;
        customerCounts[cId] = (customerCounts[cId] ?? 0) + 1;

        final currentLast = customerLastVisit[cId];
        if (currentLast == null || date.isAfter(currentLast)) {
          customerLastVisit[cId] = date;
        }
      }
    }

    // Update customer records with internally consistent stats
    for (final entry in customerTotals.entries) {
      final cId = entry.key;
      final totalSpent = entry.value;
      final totalOrders = customerCounts[cId] ?? 0;
      final lastVisit = customerLastVisit[cId]?.toIso8601String();
      // Loyalty points: 1 point per 1,000 UGX spent
      final loyaltyPoints = (totalSpent / 1000.0).floorToDouble();

      await txn.rawUpdate('''
        UPDATE customers 
        SET total_spent = ?, total_orders = ?, loyalty_points = ?, last_visit = ?
        WHERE id = ?
      ''', [totalSpent, totalOrders, loyaltyPoints, lastVisit, cId]);
    }
  }

  /// Cleanly remove development seed data without touching real user transactions
  Future<int> clearSampleData() async {
    final db = await _dbHelper.database;
    int deleted = 0;

    await db.transaction((txn) async {
      deleted += await txn.delete('transactions', where: "id LIKE 'seed_txn_%'");
      deleted += await txn.delete('customers', where: "id LIKE 'seed_c_%'");
      deleted += await txn.delete('products', where: "id LIKE 'seed_p_%'");
    });

    debugPrint('[DevDataSeeder] Removed $deleted seed entities.');
    return deleted;
  }
}
