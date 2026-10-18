import 'package:flutter_test/flutter_test.dart';
import 'package:paynest/core/constants/app_constants.dart';
import 'package:paynest/core/utils/app_utils.dart';
import 'package:paynest/data/models/models.dart';
import 'package:paynest/presentation/providers/providers.dart';

void main() {
  group('Uganda Currency & Formatting Tests', () {
    test('Default currency format uses UGX without decimals for whole numbers', () {
      expect(AppUtils.formatCurrency(50000), 'UGX 50,000');
      expect(AppUtils.formatCurrency(1000), 'UGX 1,000');
      expect(AppUtils.formatCurrency(1500000), 'UGX 1,500,000');
    });

    test('Currency format with decimals handles cents correctly', () {
      expect(AppUtils.formatCurrency(12500.50), 'UGX 12,500.50');
    });

    test('Custom currency symbol works (USh)', () {
      expect(AppUtils.formatCurrency(25000, symbol: 'USh'), 'USh 25,000');
    });

    test('Tax calculation accurately computes 18% Uganda VAT', () {
      final tax = AppUtils.calculateTax(100000, AppConstants.defaultTaxRate);
      expect(tax, 18000.0);
    });
  });

  group('CartProvider & POS Calculation Tests', () {
    test('Calculates subtotal, 18% VAT, and total correctly', () {
      final cart = CartProvider();
      final product1 = Product(
        id: 'p1',
        name: 'Chicken Rolex & Fries',
        category: 'food',
        price: 15000.0,
        stockQuantity: 50,
      );
      final product2 = Product(
        id: 'p2',
        name: 'Fresh Passion Juice',
        category: 'beverages',
        price: 7000.0,
        stockQuantity: 40,
      );

      cart.addItem(product1, quantity: 2); // 30,000
      cart.addItem(product2, quantity: 1); // 7,000

      expect(cart.itemCount, 3);
      expect(cart.subtotal, 37000.0);
      expect(cart.taxRate, 18.0);
      expect(cart.taxAmount, 37000.0 * 0.18); // 6,660.0
      expect(cart.total, 37000.0 + (37000.0 * 0.18)); // 43,660.0
    });

    test('Discount applies correctly on taxable amount', () {
      final cart = CartProvider();
      final product = Product(
        id: 'p3',
        name: 'Wireless Earbuds',
        category: 'electronics',
        price: 100000.0,
        stockQuantity: 12,
      );

      cart.addItem(product);
      cart.setDiscount(10.0); // 10% discount -> subtotal 100k, discount 10k, taxable 90k

      expect(cart.subtotal, 100000.0);
      expect(cart.discountAmount, 10000.0);
      expect(cart.taxableAmount, 90000.0);
      expect(cart.taxAmount, 90000.0 * 0.18); // 16,200
      expect(cart.total, 90000.0 + 16200.0); // 106,200
    });
  });

  group('Uganda Payment Methods Tests', () {
    test('Payment constants include MTN MoMo and Airtel Money', () {
      expect(AppConstants.paymentMtnMomo, 'MTN MoMo');
      expect(AppConstants.paymentAirtelMoney, 'Airtel Money');
      expect(AppConstants.defaultCurrency, 'UGX');
      expect(AppConstants.defaultCurrencySymbol, 'UGX');
      expect(AppConstants.defaultTaxRate, 18.0);
    });
  });
}
