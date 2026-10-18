class AppConstants {
  static const String appName = 'PayNest';
  static const String appVersion = '1.0.0';
  static const String dbName = 'paynest.db';
  static const int dbVersion = 1;

  // Hive Box Names
  static const String settingsBox = 'settings';
  static const String cartBox = 'cart';
  static const String offlineTransactionsBox = 'offline_transactions';

  // SharedPrefs Keys
  static const String keyFirstLaunch = 'first_launch';
  static const String keyDarkMode = 'dark_mode';
  static const String keyBusinessName = 'business_name';
  static const String keyCurrencySymbol = 'currency_symbol';
  static const String keyTaxRate = 'tax_rate';
  static const String keyPinEnabled = 'pin_enabled';
  static const String keyBiometricEnabled = 'biometric_enabled';
  static const String keyLoggedIn = 'logged_in';
  static const String keyUserId = 'user_id';

  // Default Values
  static const String defaultCurrency = 'UGX';
  static const String defaultCurrencySymbol = 'UGX';
  static const double defaultTaxRate = 18.0;

  // Payment Methods
  static const String paymentCash = 'Cash';
  static const String paymentCard = 'Card';
  static const String paymentMtnMomo = 'MTN MoMo';
  static const String paymentAirtelMoney = 'Airtel Money';
  static const String paymentMpesa = 'M-Pesa';
  static const String paymentBank = 'Bank Transfer';

  // Transaction Types
  static const String transactionSale = 'SALE';
  static const String transactionRefund = 'REFUND';
  static const String transactionVoid = 'VOID';

  // Status
  static const String statusCompleted = 'COMPLETED';
  static const String statusPending = 'PENDING';
  static const String statusFailed = 'FAILED';
  static const String statusRefunded = 'REFUNDED';

  // Inventory Alerts
  static const int lowStockThreshold = 10;

  // Route names
  static const String routeSplash = '/';
  static const String routeOnboarding = '/onboarding';
  static const String routeLogin = '/login';
  static const String routeHome = '/home';
  static const String routePOS = '/pos';
  static const String routeInventory = '/inventory';
  static const String routeCustomers = '/customers';
  static const String routeReports = '/reports';
  static const String routeSettings = '/settings';
  static const String routeOrders = '/orders';
  static const String routeOrderDetail = '/order-detail';
  static const String routeProductDetail = '/product-detail';
  static const String routeAddProduct = '/add-product';
  static const String routeAddCustomer = '/add-customer';
  static const String routeCheckout = '/checkout';
  static const String routeReceipt = '/receipt';
}
