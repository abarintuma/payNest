import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite/sqflite.dart';
import 'package:paynest/core/constants/app_constants.dart';
import 'package:paynest/data/datasources/local/database_helper.dart';
import 'package:paynest/data/datasources/local/dev_data_seeder.dart';
import 'package:paynest/data/repositories/repositories.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  tearDown(() async {
    await DatabaseHelper.instance.closeDB();
  });

  group('DevDataSeeder & Database Integration Tests', () {
    test('Seeder populates realistic Uganda dataset and is idempotent', () async {
      final seeder = DevDataSeeder.instance;
      final productRepo = ProductRepository();
      final customerRepo = CustomerRepository();
      final txnRepo = TransactionRepository();

      // Seed dataset
      await seeder.seedAll(force: true);

      // Verify categories
      final db = await DatabaseHelper.instance.database;
      final categories = await db.query('categories');
      expect(categories.any((c) => c['id'] == 'food'), isTrue);
      expect(categories.any((c) => c['id'] == 'beverages'), isTrue);
      expect(categories.any((c) => c['id'] == 'groceries'), isTrue);
      expect(categories.any((c) => c['id'] == 'electronics'), isTrue);

      // Verify products (100+)
      final products = await productRepo.getAllProducts();
      expect(products.length, greaterThanOrEqualTo(100));
      expect(products.any((p) => p.name.contains('Rolex')), isTrue);
      expect(products.any((p) => p.name.contains('Luwombo')), isTrue);
      expect(products.any((p) => p.taxRate == 18.0), isTrue);

      // Verify low stock and out-of-stock items exist for alerts
      final lowStock = await productRepo.getLowStockProducts(threshold: 10);
      expect(lowStock.isNotEmpty, isTrue);

      // Verify customers (100+)
      final customers = await customerRepo.getAllCustomers();
      expect(customers.length, greaterThanOrEqualTo(100));
      expect(customers.any((c) => c.name.contains('Mukasa')), isTrue);
      expect(customers.any((c) => c.phone != null && c.phone!.startsWith('+256')), isTrue);

      // Verify transactions & 18% VAT calculations (100+)
      final txns = await txnRepo.getAllTransactions();
      expect(txns.length, greaterThanOrEqualTo(100));
      for (final txn in txns) {
        expect(txn.paymentMethod, isIn([
          AppConstants.paymentCash,
          AppConstants.paymentCard,
          AppConstants.paymentMtnMomo,
          AppConstants.paymentAirtelMoney,
          AppConstants.paymentBank,
        ]));
        // Verify Uganda 18% VAT formula
        final taxableAmount = txn.subtotal - txn.discountAmount;
        final expectedTax = taxableAmount * 0.18;
        expect((txn.taxAmount - expectedTax).abs(), lessThan(0.01));
        expect((txn.total - (taxableAmount + txn.taxAmount)).abs(), lessThan(0.01));
      }

      // Verify revenue stats
      final stats = await txnRepo.getRevenueStats();
      expect(stats['totalRevenue'], greaterThan(0));
      expect(stats['totalCount'], greaterThan(0));

      // Test idempotency: Calling seedAll() a second time does not duplicate records
      final initialTxnCount = txns.length;
      final initialProductCount = products.length;

      await seeder.seedAll(force: false);

      final productsAfter = await productRepo.getAllProducts();
      final txnsAfter = await txnRepo.getAllTransactions();
      expect(productsAfter.length, initialProductCount);
      expect(txnsAfter.length, initialTxnCount);
    });
  });
}
