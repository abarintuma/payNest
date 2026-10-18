import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:paynest/data/models/models.dart';
import 'package:paynest/core/constants/app_constants.dart';

class SettingsProvider extends ChangeNotifier {
  AppSettings _settings = AppSettings();
  bool _isLoading = true;

  AppSettings get settings => _settings;
  bool get isLoading => _isLoading;
  bool get isDarkMode => _settings.darkMode;

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _settings = AppSettings(
      businessName: prefs.getString(AppConstants.keyBusinessName) ?? 'My Business',
      currencySymbol: prefs.getString(AppConstants.keyCurrencySymbol) ?? 'KSh',
      taxRate: prefs.getDouble(AppConstants.keyTaxRate) ?? 16.0,
      darkMode: prefs.getBool(AppConstants.keyDarkMode) ?? false,
      pinEnabled: prefs.getBool(AppConstants.keyPinEnabled) ?? false,
      biometricEnabled: prefs.getBool(AppConstants.keyBiometricEnabled) ?? false,
    );
    _isLoading = false;
    notifyListeners();
  }

  Future<void> updateSettings(AppSettings newSettings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.keyBusinessName, newSettings.businessName);
    await prefs.setString(AppConstants.keyCurrencySymbol, newSettings.currencySymbol);
    await prefs.setDouble(AppConstants.keyTaxRate, newSettings.taxRate);
    await prefs.setBool(AppConstants.keyDarkMode, newSettings.darkMode);
    await prefs.setBool(AppConstants.keyPinEnabled, newSettings.pinEnabled);
    await prefs.setBool(AppConstants.keyBiometricEnabled, newSettings.biometricEnabled);
    _settings = newSettings;
    notifyListeners();
  }

  Future<void> toggleDarkMode() async {
    await updateSettings(_settings.copyWith(darkMode: !_settings.darkMode));
  }
}

class CartProvider extends ChangeNotifier {
  final List<CartItem> _items = [];
  Customer? _selectedCustomer;
  double _discountPercent = 0;
  String _paymentMethod = AppConstants.paymentCash;
  String _notes = '';

  List<CartItem> get items => List.unmodifiable(_items);
  Customer? get selectedCustomer => _selectedCustomer;
  double get discountPercent => _discountPercent;
  String get paymentMethod => _paymentMethod;
  String get notes => _notes;

  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);
  bool get isEmpty => _items.isEmpty;

  double get subtotal => _items.fold(0, (sum, item) => sum + item.total);
  double get discountAmount => subtotal * (_discountPercent / 100);
  double get taxableAmount => subtotal - discountAmount;
  double get taxAmount => taxableAmount * 0.16; // 16% VAT
  double get total => taxableAmount + taxAmount;

  void addItem(Product product, {int quantity = 1}) {
    final existingIndex = _items.indexWhere((i) => i.product.id == product.id);
    if (existingIndex >= 0) {
      _items[existingIndex].quantity += quantity;
    } else {
      _items.add(CartItem(product: product, quantity: quantity));
    }
    notifyListeners();
  }

  void removeItem(String productId) {
    _items.removeWhere((i) => i.product.id == productId);
    notifyListeners();
  }

  void updateQuantity(String productId, int quantity) {
    if (quantity <= 0) {
      removeItem(productId);
      return;
    }
    final index = _items.indexWhere((i) => i.product.id == productId);
    if (index >= 0) {
      _items[index].quantity = quantity;
      notifyListeners();
    }
  }

  void setItemDiscount(String productId, double discount) {
    final index = _items.indexWhere((i) => i.product.id == productId);
    if (index >= 0) {
      _items[index].discountPercent = discount;
      notifyListeners();
    }
  }

  void setDiscount(double percent) {
    _discountPercent = percent.clamp(0, 100);
    notifyListeners();
  }

  void setPaymentMethod(String method) {
    _paymentMethod = method;
    notifyListeners();
  }

  void setCustomer(Customer? customer) {
    _selectedCustomer = customer;
    notifyListeners();
  }

  void setNotes(String notes) {
    _notes = notes;
    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    _selectedCustomer = null;
    _discountPercent = 0;
    _paymentMethod = AppConstants.paymentCash;
    _notes = '';
    notifyListeners();
  }
}

class ProductProvider extends ChangeNotifier {
  List<Product> _products = [];
  List<Product> _filteredProducts = [];
  String _selectedCategory = 'all';
  String _searchQuery = '';
  bool _isLoading = false;
  String? _error;

  List<Product> get products => _filteredProducts;
  List<Product> get allProducts => _products;
  String get selectedCategory => _selectedCategory;
  String get searchQuery => _searchQuery;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<Product> get lowStockProducts =>
      _products.where((p) => p.isLowStock).toList();
  List<Product> get outOfStockProducts =>
      _products.where((p) => p.isOutOfStock).toList();

  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void setProducts(List<Product> products) {
    _products = products;
    _applyFilters();
    notifyListeners();
  }

  void setCategory(String category) {
    _selectedCategory = category;
    _applyFilters();
    notifyListeners();
  }

  void setSearch(String query) {
    _searchQuery = query;
    _applyFilters();
    notifyListeners();
  }

  void _applyFilters() {
    var filtered = _products;
    if (_selectedCategory != 'all') {
      filtered = filtered.where((p) => p.category == _selectedCategory).toList();
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      filtered = filtered
          .where((p) =>
              p.name.toLowerCase().contains(q) ||
              (p.sku?.toLowerCase().contains(q) ?? false) ||
              (p.barcode?.toLowerCase().contains(q) ?? false))
          .toList();
    }
    _filteredProducts = filtered;
  }

  void addProduct(Product product) {
    _products.insert(0, product);
    _applyFilters();
    notifyListeners();
  }

  void updateProduct(Product updated) {
    final index = _products.indexWhere((p) => p.id == updated.id);
    if (index >= 0) {
      _products[index] = updated;
      _applyFilters();
      notifyListeners();
    }
  }

  void removeProduct(String id) {
    _products.removeWhere((p) => p.id == id);
    _applyFilters();
    notifyListeners();
  }
}

class CustomerProvider extends ChangeNotifier {
  List<Customer> _customers = [];
  List<Customer> _filtered = [];
  String _search = '';
  bool _isLoading = false;

  List<Customer> get customers => _filtered;
  bool get isLoading => _isLoading;

  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void setCustomers(List<Customer> customers) {
    _customers = customers;
    _applyFilter();
    notifyListeners();
  }

  void setSearch(String query) {
    _search = query;
    _applyFilter();
    notifyListeners();
  }

  void _applyFilter() {
    if (_search.isEmpty) {
      _filtered = _customers;
    } else {
      final q = _search.toLowerCase();
      _filtered = _customers
          .where((c) =>
              c.name.toLowerCase().contains(q) ||
              (c.phone?.contains(q) ?? false) ||
              (c.email?.toLowerCase().contains(q) ?? false))
          .toList();
    }
  }

  void addCustomer(Customer customer) {
    _customers.insert(0, customer);
    _applyFilter();
    notifyListeners();
  }

  void updateCustomer(Customer updated) {
    final index = _customers.indexWhere((c) => c.id == updated.id);
    if (index >= 0) {
      _customers[index] = updated;
      _applyFilter();
      notifyListeners();
    }
  }

  void removeCustomer(String id) {
    _customers.removeWhere((c) => c.id == id);
    _applyFilter();
    notifyListeners();
  }
}

class TransactionProvider extends ChangeNotifier {
  List<Transaction> _transactions = [];
  bool _isLoading = false;
  Map<String, dynamic> _stats = {};

  List<Transaction> get transactions => _transactions;
  bool get isLoading => _isLoading;
  Map<String, dynamic> get stats => _stats;

  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void setTransactions(List<Transaction> transactions) {
    _transactions = transactions;
    notifyListeners();
  }

  void setStats(Map<String, dynamic> stats) {
    _stats = stats;
    notifyListeners();
  }

  void addTransaction(Transaction transaction) {
    _transactions.insert(0, transaction);
    notifyListeners();
  }
}
