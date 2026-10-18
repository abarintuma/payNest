import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart' hide Transaction;
import 'package:paynest/core/constants/app_constants.dart';
import 'package:paynest/data/models/models.dart';
import 'package:paynest/data/datasources/local/database_helper.dart';
import 'package:paynest/data/datasources/remote/firebase_service.dart';
import 'package:paynest/data/datasources/remote/firestore_service.dart';
import 'package:paynest/data/repositories/repositories.dart';

/// Safe, idempotent, development-only data seeder for PayNest.
/// Populates an extensive dataset of Uganda-specific products, categories,
/// customers, and historical sales, with optional synchronization to Firebase.
class DevDataSeeder {
  static final DevDataSeeder instance = DevDataSeeder._();
  DevDataSeeder._();

  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final FirestoreService _firestoreService = FirestoreService();

  /// Check whether development seed data is already loaded in SQLite
  Future<bool> isSeeded() async {
    try {
      final db = await _dbHelper.database;
      final result = await db.rawQuery(
        "SELECT COUNT(*) as count FROM products WHERE id LIKE 'seed_p_%'",
      );
      final count = (result.first['count'] as int?) ?? 0;
      return count >= 15;
    } catch (e) {
      debugPrint('[DevDataSeeder] Error checking seed state: $e');
      return false;
    }
  }

  /// Populate the local SQLite database with extensive Uganda POS sample data
  /// and automatically synchronizes to Firebase Cloud Firestore if initialized.
  Future<void> seedAll({bool force = false}) async {
    final db = await _dbHelper.database;

    if (!force && await isSeeded()) {
      debugPrint('[DevDataSeeder] Database already populated with sample data. Skipping local generation.');
      if (FirebaseService.instance.isInitialized) {
        await syncAllToFirebase();
      }
      return;
    }

    debugPrint('[DevDataSeeder] Seeding extensive Uganda POS dataset...');

    await db.transaction((txn) async {
      await _seedCategories(txn);
      await _seedProducts(txn);
      await _seedCustomers(txn);
      await _seedTransactions(txn);
    });

    debugPrint('[DevDataSeeder] Local dataset successfully seeded.');

    // Sync to Firebase if available
    if (FirebaseService.instance.isInitialized) {
      await syncAllToFirebase();
    }
  }

  /// Synchronize all local SQLite data (products, customers, transactions) to Firestore
  Future<int> syncAllToFirebase() async {
    if (!FirebaseService.instance.isInitialized) {
      debugPrint('[DevDataSeeder] Firebase is not initialized. Skipping Firebase upload.');
      return 0;
    }

    try {
      debugPrint('[DevDataSeeder] Uploading all local data to Firebase Cloud Firestore...');
      final productRepo = ProductRepository();
      final customerRepo = CustomerRepository();
      final txnRepo = TransactionRepository();

      final products = await productRepo.getAllProducts();
      final customers = await customerRepo.getAllCustomers();
      final transactions = await txnRepo.getAllTransactions();

      final count = await _firestoreService.syncAllLocalDataToFirestore(
        products: products,
        customers: customers,
        transactions: transactions,
      );

      debugPrint('[DevDataSeeder] Cloud Firestore upload completed. Uploaded $count records.');
      return count;
    } catch (e) {
      debugPrint('[DevDataSeeder] Error uploading data to Firebase: $e');
      return 0;
    }
  }

  Future<void> _seedCategories(DatabaseExecutor txn) async {
    final categories = [
      {'id': 'all', 'name': 'All', 'icon': 'grid_view', 'color': '#6C63FF'},
      {'id': 'food', 'name': 'Food & Meals', 'icon': 'restaurant', 'color': '#FF6584'},
      {'id': 'beverages', 'name': 'Drinks & Coffee', 'icon': 'local_cafe', 'color': '#00D2AA'},
      {'id': 'groceries', 'name': 'Groceries', 'icon': 'shopping_basket', 'color': '#10B981'},
      {'id': 'electronics', 'name': 'Electronics', 'icon': 'devices', 'color': '#3DAEFF'},
      {'id': 'clothing', 'name': 'Clothing', 'icon': 'checkroom', 'color': '#FFB547'},
      {'id': 'health', 'name': 'Health & Care', 'icon': 'health_and_safety', 'color': '#EC4899'},
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

  Future<void> _seedProducts(DatabaseExecutor txn) async {
    final now = DateTime.now();
    final todayIso = now.toIso8601String();

    final products = [
      // ================= Food & Meals =================
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
        'id': 'seed_p_beef_rolex',
        'name': 'Special Beef Rolex Double',
        'description': 'Double fried eggs rolled in butter chapati with shredded tender roast beef',
        'category': 'food',
        'price': 12000.0,
        'cost_price': 5500.0,
        'stock_quantity': 50,
        'sku': 'FOD-RLX-02',
        'barcode': '600100100002',
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
        'sku': 'FOD-LWM-03',
        'barcode': '600100100003',
        'is_active': 1,
        'track_inventory': 1,
        'tax_rate': 18.0,
        'created_at': todayIso,
        'updated_at': todayIso,
      },
      {
        'id': 'seed_p_chicken_luwombo',
        'name': 'Luwombo Free-Range Chicken',
        'description': 'Local kuku stewed in peanut paste wrapped in smoked banana leaf',
        'category': 'food',
        'price': 30000.0,
        'cost_price': 16000.0,
        'stock_quantity': 20,
        'sku': 'FOD-LWM-04',
        'barcode': '600100100004',
        'is_active': 1,
        'track_inventory': 1,
        'tax_rate': 18.0,
        'created_at': todayIso,
        'updated_at': todayIso,
      },
      {
        'id': 'seed_p_tilapia',
        'name': 'Crispy Whole Tilapia with Gonja',
        'description': 'Deep-fried Lake Victoria tilapia with sweet roasted plantain and kachumbari',
        'category': 'food',
        'price': 35000.0,
        'cost_price': 19000.0,
        'stock_quantity': 18,
        'sku': 'FOD-TLP-05',
        'barcode': '600100100005',
        'is_active': 1,
        'track_inventory': 1,
        'tax_rate': 18.0,
        'created_at': todayIso,
        'updated_at': todayIso,
      },
      {
        'id': 'seed_p_katogo',
        'name': 'Katogo Breakfast Special',
        'description': 'Matooke stewed with tender beef offals, cow peas, and rich herb gravy',
        'category': 'food',
        'price': 12000.0,
        'cost_price': 5500.0,
        'stock_quantity': 35,
        'sku': 'FOD-KTG-06',
        'barcode': '600100100006',
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
        'stock_quantity': 60,
        'sku': 'FOD-SMS-07',
        'barcode': '600100100007',
        'is_active': 1,
        'track_inventory': 1,
        'tax_rate': 18.0,
        'created_at': todayIso,
        'updated_at': todayIso,
      },
      {
        'id': 'seed_p_chips_chicken',
        'name': 'Peri-Peri Chips & Grilled 1/4 Chicken',
        'description': 'Flame grilled spiced quarter chicken with crispy potato fries and garlic sauce',
        'category': 'food',
        'price': 22000.0,
        'cost_price': 11000.0,
        'stock_quantity': 30,
        'sku': 'FOD-CHK-08',
        'barcode': '600100100008',
        'is_active': 1,
        'track_inventory': 1,
        'tax_rate': 18.0,
        'created_at': todayIso,
        'updated_at': todayIso,
      },

      // ================= Drinks & Coffee =================
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
        'id': 'seed_p_iced_latte',
        'name': 'Iced Caramel Latte',
        'description': 'Chilled espresso over whole milk, ice and house-made caramel drizzle',
        'category': 'beverages',
        'price': 14000.0,
        'cost_price': 4500.0,
        'stock_quantity': 90,
        'sku': 'BEV-LTE-03',
        'barcode': '600100200003',
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
        'sku': 'BEV-PAS-04',
        'barcode': '600100200004',
        'is_active': 1,
        'track_inventory': 1,
        'tax_rate': 18.0,
        'created_at': todayIso,
        'updated_at': todayIso,
      },
      {
        'id': 'seed_p_mango_juice',
        'name': 'Fresh Mango Pulp Nectar (500ml)',
        'description': 'Sweet blended ripe Ugandan mango nectar served chilled',
        'category': 'beverages',
        'price': 7000.0,
        'cost_price': 2600.0,
        'stock_quantity': 45,
        'sku': 'BEV-MNG-05',
        'barcode': '600100200005',
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
        'sku': 'BEV-WTR-06',
        'barcode': '600100200006',
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
        'sku': 'BEV-STN-07',
        'barcode': '600100200007',
        'is_active': 1,
        'track_inventory': 1,
        'tax_rate': 18.0,
        'created_at': todayIso,
        'updated_at': todayIso,
      },
      {
        'id': 'seed_p_nile_special',
        'name': 'Nile Special Premium Lager (500ml Bottle)',
        'description': 'Uganda iconic full-bodied malt lager brewed with Nile water and local barley',
        'category': 'beverages',
        'price': 5000.0,
        'cost_price': 3200.0,
        'stock_quantity': 80,
        'sku': 'BEV-NLS-08',
        'barcode': '600100200008',
        'is_active': 1,
        'track_inventory': 1,
        'tax_rate': 18.0,
        'created_at': todayIso,
        'updated_at': todayIso,
      },

      // ================= Groceries & Pantry =================
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
        'name': 'Mukwano Fortified Cooking Oil (1L)',
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
        'stock_quantity': 35,
        'sku': 'GRO-FLR-03',
        'barcode': '600100300003',
        'is_active': 1,
        'track_inventory': 1,
        'tax_rate': 18.0,
        'created_at': todayIso,
        'updated_at': todayIso,
      },
      {
        'id': 'seed_p_rice',
        'name': 'Super Sun Aromatic Basmati Rice (2kg)',
        'description': 'Long-grain fragrant rice cleaned and polished for pilau and biryani',
        'category': 'groceries',
        'price': 18000.0,
        'cost_price': 13000.0,
        'stock_quantity': 40,
        'sku': 'GRO-RCE-04',
        'barcode': '600100300004',
        'is_active': 1,
        'track_inventory': 1,
        'tax_rate': 18.0,
        'created_at': todayIso,
        'updated_at': todayIso,
      },
      {
        'id': 'seed_p_milk',
        'name': 'Fresh Dairy Pasteurized Milk (500ml Pouch)',
        'description': 'Homogenized fresh cow milk with full cream nutrition',
        'category': 'groceries',
        'price': 2500.0,
        'cost_price': 1800.0,
        'stock_quantity': 100,
        'sku': 'GRO-MLK-05',
        'barcode': '600100300005',
        'is_active': 1,
        'track_inventory': 1,
        'tax_rate': 18.0,
        'created_at': todayIso,
        'updated_at': todayIso,
      },
      {
        'id': 'seed_p_yoghurt',
        'name': 'Jesa Vanilla Yoghurt (500g Tub)',
        'description': 'Creamy smooth vanilla flavored cultured dairy yoghurt',
        'category': 'groceries',
        'price': 6500.0,
        'cost_price': 4600.0,
        'stock_quantity': 30,
        'sku': 'GRO-YGH-06',
        'barcode': '600100300006',
        'is_active': 1,
        'track_inventory': 1,
        'tax_rate': 18.0,
        'created_at': todayIso,
        'updated_at': todayIso,
      },
      {
        'id': 'seed_p_blueband',
        'name': 'Blue Band Medium Fat Spread (250g)',
        'description': 'Classic fortified margarine spread with Omega 3 and 6',
        'category': 'groceries',
        'price': 5500.0,
        'cost_price': 3800.0,
        'stock_quantity': 50,
        'sku': 'GRO-BLB-07',
        'barcode': '600100300007',
        'is_active': 1,
        'track_inventory': 1,
        'tax_rate': 18.0,
        'created_at': todayIso,
        'updated_at': todayIso,
      },
      {
        'id': 'seed_p_royco',
        'name': 'Royco Mchuzi Mix Beef Seasoning (200g)',
        'description': 'Popular aromatic food seasoning for richer stew thickness and flavor',
        'category': 'groceries',
        'price': 4500.0,
        'cost_price': 3000.0,
        'stock_quantity': 75,
        'sku': 'GRO-RYC-08',
        'barcode': '600100300008',
        'is_active': 1,
        'track_inventory': 1,
        'tax_rate': 18.0,
        'created_at': todayIso,
        'updated_at': todayIso,
      },

      // ================= Electronics & Mobile =================
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
        'stock_quantity': 5, // Low stock item (< 10) for testing low-stock alerts
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
        'id': 'seed_p_lightning',
        'name': 'Apple Lightning to USB Fast Charge Cable (1.5M)',
        'description': 'MFi-certified charging cable for iPhone and iPad devices',
        'category': 'electronics',
        'price': 20000.0,
        'cost_price': 9000.0,
        'stock_quantity': 25,
        'sku': 'ELC-LTN-04',
        'barcode': '600100400004',
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
        'sku': 'ELC-CHG-05',
        'barcode': '600100400005',
        'is_active': 1,
        'track_inventory': 1,
        'tax_rate': 18.0,
        'created_at': todayIso,
        'updated_at': todayIso,
      },
      {
        'id': 'seed_p_extension',
        'name': 'Surge Protector 4-Way Power Strip (3 Metres)',
        'description': 'Heavy-duty extension with individual master power switches and USB ports',
        'category': 'electronics',
        'price': 45000.0,
        'cost_price': 25000.0,
        'stock_quantity': 18,
        'sku': 'ELC-EXT-06',
        'barcode': '600100400006',
        'is_active': 1,
        'track_inventory': 1,
        'tax_rate': 18.0,
        'created_at': todayIso,
        'updated_at': todayIso,
      },

      // ================= Clothing & Apparel =================
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
      {
        'id': 'seed_p_crest_tee',
        'name': 'Uganda Crest Graphic Tee (100% Cotton)',
        'description': 'Soft spun cotton crew neck t-shirt featuring the Crested Crane emblem',
        'category': 'clothing',
        'price': 35000.0,
        'cost_price': 16000.0,
        'stock_quantity': 35,
        'sku': 'CLT-TEE-03',
        'barcode': '600100500003',
        'is_active': 1,
        'track_inventory': 1,
        'tax_rate': 18.0,
        'created_at': todayIso,
        'updated_at': todayIso,
      },
      {
        'id': 'seed_p_loafers',
        'name': 'Canvas Slip-On Loafers (Casual Comfort)',
        'description': 'Flexible lightweight casual loafers with cushioned insole and rubber outsole',
        'category': 'clothing',
        'price': 75000.0,
        'cost_price': 40000.0,
        'stock_quantity': 4, // Low stock item (< 10)
        'sku': 'CLT-LFR-04',
        'barcode': '600100500004',
        'is_active': 1,
        'track_inventory': 1,
        'tax_rate': 18.0,
        'created_at': todayIso,
        'updated_at': todayIso,
      },

      // ================= Health, Hygiene & Care =================
      {
        'id': 'seed_p_dettol',
        'name': 'Dettol Antiseptic Liquid (250ml)',
        'description': 'Effective concentrated antiseptic solution for wound care and household hygiene',
        'category': 'health',
        'price': 16000.0,
        'cost_price': 11000.0,
        'stock_quantity': 40,
        'sku': 'HLT-DTL-01',
        'barcode': '600100600001',
        'is_active': 1,
        'track_inventory': 1,
        'tax_rate': 18.0,
        'created_at': todayIso,
        'updated_at': todayIso,
      },
      {
        'id': 'seed_p_omo',
        'name': 'Omo Auto Washing Powder (500g)',
        'description': 'Fast-acting detergent powder with deep stain removing power and fresh fragrance',
        'category': 'health',
        'price': 7500.0,
        'cost_price': 5200.0,
        'stock_quantity': 45,
        'sku': 'HLT-OMO-02',
        'barcode': '600100600002',
        'is_active': 1,
        'track_inventory': 1,
        'tax_rate': 18.0,
        'created_at': todayIso,
        'updated_at': todayIso,
      },
      {
        'id': 'seed_p_colgate',
        'name': 'Colgate Total 12 Active Fresh (100ml)',
        'description': 'Antibacterial fluoride toothpaste for whole mouth health and fresh breath',
        'category': 'health',
        'price': 8000.0,
        'cost_price': 5500.0,
        'stock_quantity': 60,
        'sku': 'HLT-CLG-03',
        'barcode': '600100600003',
        'is_active': 1,
        'track_inventory': 1,
        'tax_rate': 18.0,
        'created_at': todayIso,
        'updated_at': todayIso,
      },
      {
        'id': 'seed_p_geisha',
        'name': 'Geisha Herbal Bathing Soap (225g Bar)',
        'description': 'Long-lasting natural herbal beauty bar with extracts of neem and green tea',
        'category': 'health',
        'price': 4000.0,
        'cost_price': 2700.0,
        'stock_quantity': 90,
        'sku': 'HLT-GSH-04',
        'barcode': '600100600004',
        'is_active': 1,
        'track_inventory': 1,
        'tax_rate': 18.0,
        'created_at': todayIso,
        'updated_at': todayIso,
      },
      {
        'id': 'seed_p_tissue',
        'name': 'Bella Soft 2-Ply Toilet Tissue (Pack of 4)',
        'description': 'Super-absorbent, virgin pulp embossed white soft tissue rolls',
        'category': 'health',
        'price': 10000.0,
        'cost_price': 6500.0,
        'stock_quantity': 50,
        'sku': 'HLT-TSS-05',
        'barcode': '600100600005',
        'is_active': 1,
        'track_inventory': 1,
        'tax_rate': 18.0,
        'created_at': todayIso,
        'updated_at': todayIso,
      },

      // ================= Services & Telecom =================
      {
        'id': 'seed_p_mtn_airtime',
        'name': 'MTN Airtime Electronic Top-up (UGX 10,000)',
        'description': 'Instant prepaid airtime credit voucher valid on all MTN Uganda lines',
        'category': 'services',
        'price': 10000.0,
        'cost_price': 9600.0,
        'stock_quantity': 999,
        'sku': 'SRV-MTN-01',
        'barcode': '600100700001',
        'is_active': 1,
        'track_inventory': 0, // Non-inventory item
        'tax_rate': 0.0, // Airtime tax handled at telecom level
        'created_at': todayIso,
        'updated_at': todayIso,
      },
      {
        'id': 'seed_p_airtel_airtime',
        'name': 'Airtel Airtime Electronic Top-up (UGX 10,000)',
        'description': 'Instant prepaid airtime credit voucher for Airtel Uganda subscribers',
        'category': 'services',
        'price': 10000.0,
        'cost_price': 9600.0,
        'stock_quantity': 999,
        'sku': 'SRV-ATL-02',
        'barcode': '600100700002',
        'is_active': 1,
        'track_inventory': 0,
        'tax_rate': 0.0,
        'created_at': todayIso,
        'updated_at': todayIso,
      },
      {
        'id': 'seed_p_yaka',
        'name': 'UMEME Yaka Electricity Token (UGX 50,000)',
        'description': 'Domestic prepaid electricity voucher token for domestic meters',
        'category': 'services',
        'price': 50000.0,
        'cost_price': 48500.0,
        'stock_quantity': 999,
        'sku': 'SRV-YKA-03',
        'barcode': '600100700003',
        'is_active': 1,
        'track_inventory': 0,
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

  Future<void> _seedCustomers(DatabaseExecutor txn) async {
    final now = DateTime.now();

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
      {
        'id': 'seed_c_namubiru',
        'name': 'Sarah Namubiru',
        'email': 'sarah.namubiru@makerere.ac.ug',
        'phone': '+256702334455',
        'address': 'Wandegeya Flats, Block 4, Makerere',
        'total_spent': 0.0,
        'total_orders': 0,
        'notes': 'Makerere University lecturer; regular book and stationery shopper',
        'created_at': now.subtract(const Duration(days: 50)).toIso8601String(),
        'last_visit': now.subtract(const Duration(days: 1)).toIso8601String(),
        'loyalty_points': 0.0,
      },
      {
        'id': 'seed_c_kigozi',
        'name': 'Patrick Kigozi',
        'email': 'patrick.kigozi@finance.go.ug',
        'phone': '+256784112233',
        'address': 'Nakasero Hill Road, Kampala',
        'total_spent': 0.0,
        'total_orders': 0,
        'notes': 'Government consultant; prefers bank transfers and invoices',
        'created_at': now.subtract(const Duration(days: 70)).toIso8601String(),
        'last_visit': now.subtract(const Duration(days: 5)).toIso8601String(),
        'loyalty_points': 0.0,
      },
      {
        'id': 'seed_c_akello',
        'name': 'Florence Akello',
        'email': 'florence.akello@gmail.com',
        'phone': '+256758667788',
        'address': 'Kyanja Ring Road, Kawempe',
        'total_spent': 0.0,
        'total_orders': 0,
        'notes': 'Regular grocery household restocker',
        'created_at': now.subtract(const Duration(days: 35)).toIso8601String(),
        'last_visit': now.subtract(const Duration(days: 2)).toIso8601String(),
        'loyalty_points': 0.0,
      },
      {
        'id': 'seed_c_mugisha',
        'name': 'Brian Mugisha',
        'email': 'brian.mugisha@tech.ug',
        'phone': '+256779889900',
        'address': 'Bunga Hill, Ggaba Road, Makindye',
        'total_spent': 0.0,
        'total_orders': 0,
        'notes': 'Software developer; frequent gadgets and coffee buyer',
        'created_at': now.subtract(const Duration(days: 25)).toIso8601String(),
        'last_visit': now.subtract(const Duration(days: 1)).toIso8601String(),
        'loyalty_points': 0.0,
      },
      {
        'id': 'seed_c_nabukenya',
        'name': 'Joan Nabukenya',
        'email': 'joan.nabukenya@estate.ug',
        'phone': '+256705445566',
        'address': 'Naalya Housing Estate, Kira Municipality',
        'total_spent': 0.0,
        'total_orders': 0,
        'notes': 'Bakery and household toiletries enthusiast',
        'created_at': now.subtract(const Duration(days: 40)).toIso8601String(),
        'last_visit': now.subtract(const Duration(days: 6)).toIso8601String(),
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

  Future<void> _seedTransactions(DatabaseExecutor txn) async {
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
      double taxRate = 18.0,
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
      final taxAmount = (taxRate > 0) ? (taxableAmount * (taxRate / 100)) : 0.0;
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
        'is_synced': 1,
        'created_at': date.toIso8601String(),
      };
    }

    final txnData = [
      // ================= Day 0: TODAY =================
      createTxnRecord(
        id: 'seed_txn_101',
        receiptNumber: 'RCP-DEMO-2001',
        date: now.subtract(const Duration(minutes: 45)),
        paymentMethod: AppConstants.paymentMtnMomo,
        customerId: 'seed_c_mukasa',
        customerName: 'Kato Mukasa',
        items: [
          {'product_id': 'seed_p_rolex', 'product_name': 'Chicken Rolex & Fries', 'price': 15000.0, 'quantity': 2},
          {'product_id': 'seed_p_passion_juice', 'product_name': 'Fresh Masaka Passion Fruit Juice', 'price': 7000.0, 'quantity': 2},
        ],
      ),
      createTxnRecord(
        id: 'seed_txn_102',
        receiptNumber: 'RCP-DEMO-2002',
        date: now.subtract(const Duration(hours: 2, minutes: 15)),
        paymentMethod: AppConstants.paymentCash,
        customerId: null,
        customerName: 'Walk-in Cashier Guest',
        cashAmountPaid: 50000.0,
        items: [
          {'product_id': 'seed_p_tilapia', 'product_name': 'Crispy Whole Tilapia with Gonja', 'price': 35000.0, 'quantity': 1},
          {'product_id': 'seed_p_stoney', 'product_name': 'Stoney Tangawisi Ginger Beer', 'price': 3000.0, 'quantity': 2},
        ],
      ),
      createTxnRecord(
        id: 'seed_txn_103',
        receiptNumber: 'RCP-DEMO-2003',
        date: now.subtract(const Duration(hours: 3, minutes: 30)),
        paymentMethod: AppConstants.paymentAirtelMoney,
        customerId: 'seed_c_nakato',
        customerName: 'Babirye Nakato',
        items: [
          {'product_id': 'seed_p_cappuccino', 'product_name': 'Steamed Cappuccino', 'price': 10000.0, 'quantity': 2},
          {'product_id': 'seed_p_samosa', 'product_name': 'Beef Samosa Platter (Pack of 6)', 'price': 10000.0, 'quantity': 1},
        ],
      ),
      createTxnRecord(
        id: 'seed_txn_104',
        receiptNumber: 'RCP-DEMO-2004',
        date: now.subtract(const Duration(hours: 5)),
        paymentMethod: AppConstants.paymentMtnMomo,
        customerId: 'seed_c_mugisha',
        customerName: 'Brian Mugisha',
        items: [
          {'product_id': 'seed_p_cable', 'product_name': 'Braided Type-C Fast Cable', 'price': 25000.0, 'quantity': 2},
          {'product_id': 'seed_p_espresso', 'product_name': 'Single Espresso', 'price': 6000.0, 'quantity': 1},
        ],
      ),
      createTxnRecord(
        id: 'seed_txn_105',
        receiptNumber: 'RCP-DEMO-2005',
        date: now.subtract(const Duration(hours: 6, minutes: 20)),
        paymentMethod: AppConstants.paymentCard,
        customerId: 'seed_c_namubiru',
        customerName: 'Sarah Namubiru',
        items: [
          {'product_id': 'seed_p_sugar', 'product_name': 'Kakira Pure White Sugar (1kg)', 'price': 6000.0, 'quantity': 3},
          {'product_id': 'seed_p_oil', 'product_name': 'Mukwano Cooking Oil (1L)', 'price': 11500.0, 'quantity': 2},
          {'product_id': 'seed_p_flour', 'product_name': 'Supreme Bakers Flour (2kg)', 'price': 9500.0, 'quantity': 2},
        ],
      ),

      // ================= Day 1: YESTERDAY =================
      createTxnRecord(
        id: 'seed_txn_106',
        receiptNumber: 'RCP-DEMO-2006',
        date: now.subtract(const Duration(days: 1, hours: 2)),
        paymentMethod: AppConstants.paymentCard,
        customerId: 'seed_c_ainembabazi',
        customerName: 'Grace Ainembabazi',
        items: [
          {'product_id': 'seed_p_kitenge', 'product_name': 'Modern Kitenge African Print Shirt', 'price': 65000.0, 'quantity': 1},
          {'product_id': 'seed_p_iced_latte', 'product_name': 'Iced Caramel Latte', 'price': 14000.0, 'quantity': 1},
        ],
      ),
      createTxnRecord(
        id: 'seed_txn_107',
        receiptNumber: 'RCP-DEMO-2007',
        date: now.subtract(const Duration(days: 1, hours: 4)),
        paymentMethod: AppConstants.paymentMtnMomo,
        customerId: 'seed_c_okello',
        customerName: 'Ronald Okello',
        discountPercent: 5.0, // 5% discount
        items: [
          {'product_id': 'seed_p_oil', 'product_name': 'Mukwano Cooking Oil (1L)', 'price': 11500.0, 'quantity': 4},
          {'product_id': 'seed_p_rice', 'product_name': 'Super Sun Basmati Rice (2kg)', 'price': 18000.0, 'quantity': 3},
        ],
      ),
      createTxnRecord(
        id: 'seed_txn_108',
        receiptNumber: 'RCP-DEMO-2008',
        date: now.subtract(const Duration(days: 1, hours: 6)),
        paymentMethod: AppConstants.paymentCash,
        cashAmountPaid: 70000.0,
        items: [
          {'product_id': 'seed_p_chips_chicken', 'product_name': 'Peri-Peri Chips & Grilled Chicken', 'price': 22000.0, 'quantity': 2},
          {'product_id': 'seed_p_nile_special', 'product_name': 'Nile Special Premium Lager', 'price': 5000.0, 'quantity': 4},
        ],
      ),
      createTxnRecord(
        id: 'seed_txn_109',
        receiptNumber: 'RCP-DEMO-2009',
        date: now.subtract(const Duration(days: 1, hours: 8)),
        paymentMethod: AppConstants.paymentAirtelMoney,
        customerId: 'seed_c_akello',
        customerName: 'Florence Akello',
        items: [
          {'product_id': 'seed_p_dettol', 'product_name': 'Dettol Antiseptic Liquid (250ml)', 'price': 16000.0, 'quantity': 2},
          {'product_id': 'seed_p_omo', 'product_name': 'Omo Auto Washing Powder (500g)', 'price': 7500.0, 'quantity': 2},
          {'product_id': 'seed_p_tissue', 'product_name': 'Bella Soft Toilet Tissue (4pk)', 'price': 10000.0, 'quantity': 2},
        ],
      ),

      // ================= Day 2: 2 DAYS AGO =================
      createTxnRecord(
        id: 'seed_txn_110',
        receiptNumber: 'RCP-DEMO-2010',
        date: now.subtract(const Duration(days: 2, hours: 3)),
        paymentMethod: AppConstants.paymentBank,
        customerId: 'seed_c_kigozi',
        customerName: 'Patrick Kigozi',
        items: [
          {'product_id': 'seed_p_powerbank', 'product_name': 'Oraimo 10,000mAh Power Bank', 'price': 75000.0, 'quantity': 3},
          {'product_id': 'seed_p_extension', 'product_name': 'Surge Protector 4-Way Power Strip', 'price': 45000.0, 'quantity': 2},
        ],
      ),
      createTxnRecord(
        id: 'seed_txn_111',
        receiptNumber: 'RCP-DEMO-2011',
        date: now.subtract(const Duration(days: 2, hours: 5)),
        paymentMethod: AppConstants.paymentCash,
        cashAmountPaid: 40000.0,
        items: [
          {'product_id': 'seed_p_luwombo', 'product_name': 'Luwombo Beef & Matooke', 'price': 28000.0, 'quantity': 1},
          {'product_id': 'seed_p_water', 'product_name': 'Rwenzori Mineral Water', 'price': 2000.0, 'quantity': 2},
        ],
      ),
      createTxnRecord(
        id: 'seed_txn_112',
        receiptNumber: 'RCP-DEMO-2012',
        date: now.subtract(const Duration(days: 2, hours: 7)),
        paymentMethod: AppConstants.paymentMtnMomo,
        customerId: 'seed_c_mukasa',
        customerName: 'Kato Mukasa',
        items: [
          {'product_id': 'seed_p_polo', 'product_name': 'Breathable Cotton Pique Polo', 'price': 45000.0, 'quantity': 1},
          {'product_id': 'seed_p_crest_tee', 'product_name': 'Uganda Crest Graphic Tee', 'price': 35000.0, 'quantity': 1},
        ],
      ),

      // ================= Day 3: 3 DAYS AGO =================
      createTxnRecord(
        id: 'seed_txn_113',
        receiptNumber: 'RCP-DEMO-2013',
        date: now.subtract(const Duration(days: 3, hours: 2)),
        paymentMethod: AppConstants.paymentAirtelMoney,
        customerId: 'seed_c_wasswa',
        customerName: 'David Wasswa',
        items: [
          {'product_id': 'seed_p_earbuds', 'product_name': 'Wireless Bluetooth Earbuds', 'price': 85000.0, 'quantity': 1},
          {'product_id': 'seed_p_lightning', 'product_name': 'Apple Lightning Fast Cable', 'price': 20000.0, 'quantity': 1},
        ],
      ),
      createTxnRecord(
        id: 'seed_txn_114',
        receiptNumber: 'RCP-DEMO-2014',
        date: now.subtract(const Duration(days: 3, hours: 4)),
        paymentMethod: AppConstants.paymentMtnMomo,
        customerId: 'seed_c_okello',
        customerName: 'Ronald Okello',
        items: [
          {'product_id': 'seed_p_sugar', 'product_name': 'Kakira Pure White Sugar', 'price': 6000.0, 'quantity': 10},
          {'product_id': 'seed_p_flour', 'product_name': 'Supreme Bakers Flour', 'price': 9500.0, 'quantity': 5},
        ],
      ),
      createTxnRecord(
        id: 'seed_txn_115',
        receiptNumber: 'RCP-DEMO-2015',
        date: now.subtract(const Duration(days: 3, hours: 6)),
        paymentMethod: AppConstants.paymentCash,
        cashAmountPaid: 50000.0,
        items: [
          {'product_id': 'seed_p_beef_rolex', 'product_name': 'Special Beef Rolex Double', 'price': 12000.0, 'quantity': 3},
          {'product_id': 'seed_p_mango_juice', 'product_name': 'Fresh Mango Pulp Nectar', 'price': 7000.0, 'quantity': 2},
        ],
      ),

      // ================= Day 4: 4 DAYS AGO =================
      createTxnRecord(
        id: 'seed_txn_116',
        receiptNumber: 'RCP-DEMO-2016',
        date: now.subtract(const Duration(days: 4, hours: 2)),
        paymentMethod: AppConstants.paymentCard,
        customerId: 'seed_c_nabukenya',
        customerName: 'Joan Nabukenya',
        items: [
          {'product_id': 'seed_p_loafers', 'product_name': 'Canvas Slip-On Loafers', 'price': 75000.0, 'quantity': 1},
          {'product_id': 'seed_p_cappuccino', 'product_name': 'Steamed Cappuccino', 'price': 10000.0, 'quantity': 1},
        ],
      ),
      createTxnRecord(
        id: 'seed_txn_117',
        receiptNumber: 'RCP-DEMO-2017',
        date: now.subtract(const Duration(days: 4, hours: 5)),
        paymentMethod: AppConstants.paymentCash,
        cashAmountPaid: 100000.0,
        items: [
          {'product_id': 'seed_p_chicken_luwombo', 'product_name': 'Luwombo Free-Range Chicken', 'price': 30000.0, 'quantity': 2},
          {'product_id': 'seed_p_passion_juice', 'product_name': 'Fresh Masaka Passion Juice', 'price': 7000.0, 'quantity': 4},
        ],
      ),
      createTxnRecord(
        id: 'seed_txn_118',
        receiptNumber: 'RCP-DEMO-2018',
        date: now.subtract(const Duration(days: 4, hours: 7)),
        paymentMethod: AppConstants.paymentMtnMomo,
        customerId: 'seed_c_akello',
        customerName: 'Florence Akello',
        items: [
          {'product_id': 'seed_p_milk', 'product_name': 'Fresh Dairy Milk 500ml', 'price': 2500.0, 'quantity': 6},
          {'product_id': 'seed_p_yoghurt', 'product_name': 'Jesa Vanilla Yoghurt 500g', 'price': 6500.0, 'quantity': 4},
          {'product_id': 'seed_p_blueband', 'product_name': 'Blue Band Margarine 250g', 'price': 5500.0, 'quantity': 2},
        ],
      ),

      // ================= Day 5: 5 DAYS AGO =================
      createTxnRecord(
        id: 'seed_txn_119',
        receiptNumber: 'RCP-DEMO-2019',
        date: now.subtract(const Duration(days: 5, hours: 3)),
        paymentMethod: AppConstants.paymentAirtelMoney,
        customerId: 'seed_c_nakato',
        customerName: 'Babirye Nakato',
        items: [
          {'product_id': 'seed_p_katogo', 'product_name': 'Katogo Breakfast Special', 'price': 12000.0, 'quantity': 4},
          {'product_id': 'seed_p_passion_juice', 'product_name': 'Fresh Passion Fruit Juice', 'price': 7000.0, 'quantity': 2},
        ],
      ),
      createTxnRecord(
        id: 'seed_txn_120',
        receiptNumber: 'RCP-DEMO-2020',
        date: now.subtract(const Duration(days: 5, hours: 6)),
        paymentMethod: AppConstants.paymentCash,
        cashAmountPaid: 60000.0,
        items: [
          {'product_id': 'seed_p_rolex', 'product_name': 'Chicken Rolex & Fries', 'price': 15000.0, 'quantity': 3},
          {'product_id': 'seed_p_water', 'product_name': 'Rwenzori Mineral Water', 'price': 2000.0, 'quantity': 3},
        ],
      ),

      // ================= Day 6: 6 DAYS AGO =================
      createTxnRecord(
        id: 'seed_txn_121',
        receiptNumber: 'RCP-DEMO-2021',
        date: now.subtract(const Duration(days: 6, hours: 4)),
        paymentMethod: AppConstants.paymentMtnMomo,
        customerId: 'seed_c_mukasa',
        customerName: 'Kato Mukasa',
        items: [
          {'product_id': 'seed_p_rolex', 'product_name': 'Chicken Rolex & Fries', 'price': 15000.0, 'quantity': 3},
          {'product_id': 'seed_p_cappuccino', 'product_name': 'Steamed Cappuccino', 'price': 10000.0, 'quantity': 3},
        ],
      ),
      createTxnRecord(
        id: 'seed_txn_122',
        receiptNumber: 'RCP-DEMO-2022',
        date: now.subtract(const Duration(days: 6, hours: 7)),
        paymentMethod: AppConstants.paymentCard,
        customerId: 'seed_c_kigozi',
        customerName: 'Patrick Kigozi',
        discountPercent: 10.0, // 10% executive discount
        items: [
          {'product_id': 'seed_p_tilapia', 'product_name': 'Crispy Whole Tilapia with Gonja', 'price': 35000.0, 'quantity': 2},
          {'product_id': 'seed_p_luwombo', 'product_name': 'Luwombo Beef & Matooke', 'price': 28000.0, 'quantity': 2},
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
