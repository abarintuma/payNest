import 'dart:convert';

class Product {
  final String id;
  final String name;
  final String? description;
  final String category;
  final double price;
  final double? costPrice;
  final int stockQuantity;
  final String? sku;
  final String? barcode;
  final String? imageUrl;
  final bool isActive;
  final bool trackInventory;
  final double? taxRate;
  final DateTime createdAt;
  final DateTime updatedAt;

  Product({
    required this.id,
    required this.name,
    this.description,
    required this.category,
    required this.price,
    this.costPrice,
    required this.stockQuantity,
    this.sku,
    this.barcode,
    this.imageUrl,
    this.isActive = true,
    this.trackInventory = true,
    this.taxRate,
    required this.createdAt,
    required this.updatedAt,
  });

  Product copyWith({
    String? id,
    String? name,
    String? description,
    String? category,
    double? price,
    double? costPrice,
    int? stockQuantity,
    String? sku,
    String? barcode,
    String? imageUrl,
    bool? isActive,
    bool? trackInventory,
    double? taxRate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      price: price ?? this.price,
      costPrice: costPrice ?? this.costPrice,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      sku: sku ?? this.sku,
      barcode: barcode ?? this.barcode,
      imageUrl: imageUrl ?? this.imageUrl,
      isActive: isActive ?? this.isActive,
      trackInventory: trackInventory ?? this.trackInventory,
      taxRate: taxRate ?? this.taxRate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category': category,
      'price': price,
      'cost_price': costPrice,
      'stock_quantity': stockQuantity,
      'sku': sku,
      'barcode': barcode,
      'image_url': imageUrl,
      'is_active': isActive ? 1 : 0,
      'track_inventory': trackInventory ? 1 : 0,
      'tax_rate': taxRate,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      category: map['category'],
      price: (map['price'] as num).toDouble(),
      costPrice: map['cost_price'] != null ? (map['cost_price'] as num).toDouble() : null,
      stockQuantity: map['stock_quantity'] as int,
      sku: map['sku'],
      barcode: map['barcode'],
      imageUrl: map['image_url'],
      isActive: (map['is_active'] as int) == 1,
      trackInventory: (map['track_inventory'] as int) == 1,
      taxRate: map['tax_rate'] != null ? (map['tax_rate'] as num).toDouble() : null,
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }

  String toJson() => jsonEncode(toMap());
  factory Product.fromJson(String source) => Product.fromMap(jsonDecode(source));

  double get profit => costPrice != null ? price - costPrice! : 0;
  double get profitMargin => costPrice != null && costPrice! > 0
      ? ((price - costPrice!) / price) * 100
      : 0;

  bool get isLowStock => stockQuantity <= 10 && stockQuantity > 0;
  bool get isOutOfStock => stockQuantity == 0;
}

class CartItem {
  final Product product;
  int quantity;
  double? discountPercent;
  String? note;

  CartItem({
    required this.product,
    required this.quantity,
    this.discountPercent,
    this.note,
  });

  double get subtotal => product.price * quantity;
  double get discountAmount =>
      discountPercent != null ? subtotal * (discountPercent! / 100) : 0;
  double get total => subtotal - discountAmount;
}

class Customer {
  final String id;
  final String name;
  final String? email;
  final String? phone;
  final String? address;
  final double totalSpent;
  final int totalOrders;
  final String? notes;
  final DateTime createdAt;
  final DateTime? lastVisit;
  final double? loyaltyPoints;

  Customer({
    required this.id,
    required this.name,
    this.email,
    this.phone,
    this.address,
    this.totalSpent = 0,
    this.totalOrders = 0,
    this.notes,
    required this.createdAt,
    this.lastVisit,
    this.loyaltyPoints,
  });

  Customer copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? address,
    double? totalSpent,
    int? totalOrders,
    String? notes,
    DateTime? createdAt,
    DateTime? lastVisit,
    double? loyaltyPoints,
  }) {
    return Customer(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      totalSpent: totalSpent ?? this.totalSpent,
      totalOrders: totalOrders ?? this.totalOrders,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      lastVisit: lastVisit ?? this.lastVisit,
      loyaltyPoints: loyaltyPoints ?? this.loyaltyPoints,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'address': address,
      'total_spent': totalSpent,
      'total_orders': totalOrders,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'last_visit': lastVisit?.toIso8601String(),
      'loyalty_points': loyaltyPoints,
    };
  }

  factory Customer.fromMap(Map<String, dynamic> map) {
    return Customer(
      id: map['id'],
      name: map['name'],
      email: map['email'],
      phone: map['phone'],
      address: map['address'],
      totalSpent: (map['total_spent'] as num?)?.toDouble() ?? 0,
      totalOrders: map['total_orders'] as int? ?? 0,
      notes: map['notes'],
      createdAt: DateTime.parse(map['created_at']),
      lastVisit: map['last_visit'] != null ? DateTime.parse(map['last_visit']) : null,
      loyaltyPoints: (map['loyalty_points'] as num?)?.toDouble(),
    );
  }

  String get initials {
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }
}

class Transaction {
  final String id;
  final String receiptNumber;
  final List<TransactionItem> items;
  final double subtotal;
  final double taxAmount;
  final double discountAmount;
  final double total;
  final double amountPaid;
  final double change;
  final String paymentMethod;
  final String status;
  final String type;
  final String? customerId;
  final String? customerName;
  final String? notes;
  final bool isSynced;
  final DateTime createdAt;

  Transaction({
    required this.id,
    required this.receiptNumber,
    required this.items,
    required this.subtotal,
    required this.taxAmount,
    required this.discountAmount,
    required this.total,
    required this.amountPaid,
    required this.change,
    required this.paymentMethod,
    required this.status,
    required this.type,
    this.customerId,
    this.customerName,
    this.notes,
    this.isSynced = false,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'receipt_number': receiptNumber,
      'items': jsonEncode(items.map((i) => i.toMap()).toList()),
      'subtotal': subtotal,
      'tax_amount': taxAmount,
      'discount_amount': discountAmount,
      'total': total,
      'amount_paid': amountPaid,
      'change': change,
      'payment_method': paymentMethod,
      'status': status,
      'type': type,
      'customer_id': customerId,
      'customer_name': customerName,
      'notes': notes,
      'is_synced': isSynced ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Transaction.fromMap(Map<String, dynamic> map) {
    final itemsList = jsonDecode(map['items'] as String) as List;
    return Transaction(
      id: map['id'],
      receiptNumber: map['receipt_number'],
      items: itemsList.map((i) => TransactionItem.fromMap(i)).toList(),
      subtotal: (map['subtotal'] as num).toDouble(),
      taxAmount: (map['tax_amount'] as num).toDouble(),
      discountAmount: (map['discount_amount'] as num).toDouble(),
      total: (map['total'] as num).toDouble(),
      amountPaid: (map['amount_paid'] as num).toDouble(),
      change: (map['change'] as num).toDouble(),
      paymentMethod: map['payment_method'],
      status: map['status'],
      type: map['type'],
      customerId: map['customer_id'],
      customerName: map['customer_name'],
      notes: map['notes'],
      isSynced: (map['is_synced'] as int) == 1,
      createdAt: DateTime.parse(map['created_at']),
    );
  }
}

class TransactionItem {
  final String productId;
  final String productName;
  final double price;
  final int quantity;
  final double? discountPercent;

  TransactionItem({
    required this.productId,
    required this.productName,
    required this.price,
    required this.quantity,
    this.discountPercent,
  });

  double get total => price * quantity * (1 - (discountPercent ?? 0) / 100);

  Map<String, dynamic> toMap() {
    return {
      'product_id': productId,
      'product_name': productName,
      'price': price,
      'quantity': quantity,
      'discount_percent': discountPercent,
    };
  }

  factory TransactionItem.fromMap(Map<String, dynamic> map) {
    return TransactionItem(
      productId: map['product_id'],
      productName: map['product_name'],
      price: (map['price'] as num).toDouble(),
      quantity: map['quantity'] as int,
      discountPercent: map['discount_percent'] != null
          ? (map['discount_percent'] as num).toDouble()
          : null,
    );
  }
}

class Category {
  final String id;
  final String name;
  final String? icon;
  final String? color;
  final int productCount;

  Category({
    required this.id,
    required this.name,
    this.icon,
    this.color,
    this.productCount = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'color': color,
      'product_count': productCount,
    };
  }

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'],
      name: map['name'],
      icon: map['icon'],
      color: map['color'],
      productCount: map['product_count'] as int? ?? 0,
    );
  }

  static List<Category> get defaults => [
    Category(id: 'all', name: 'All', icon: 'grid_view'),
    Category(id: 'food', name: 'Food', icon: 'restaurant'),
    Category(id: 'beverages', name: 'Drinks', icon: 'local_cafe'),
    Category(id: 'electronics', name: 'Electronics', icon: 'devices'),
    Category(id: 'clothing', name: 'Clothing', icon: 'checkroom'),
    Category(id: 'beauty', name: 'Beauty', icon: 'spa'),
    Category(id: 'health', name: 'Health', icon: 'favorite'),
    Category(id: 'other', name: 'Other', icon: 'more_horiz'),
  ];
}

class AppSettings {
  final String businessName;
  final String? businessAddress;
  final String? businessPhone;
  final String? businessEmail;
  final String currencySymbol;
  final double taxRate;
  final bool taxIncluded;
  final bool darkMode;
  final bool pinEnabled;
  final bool biometricEnabled;
  final bool printReceiptAuto;
  final String? receiptFooter;
  final String? logoPath;

  AppSettings({
    this.businessName = 'My Business',
    this.businessAddress,
    this.businessPhone,
    this.businessEmail,
    this.currencySymbol = 'UGX',
    this.taxRate = 18.0,
    this.taxIncluded = false,
    this.darkMode = false,
    this.pinEnabled = false,
    this.biometricEnabled = false,
    this.printReceiptAuto = false,
    this.receiptFooter,
    this.logoPath,
  });

  AppSettings copyWith({
    String? businessName,
    String? businessAddress,
    String? businessPhone,
    String? businessEmail,
    String? currencySymbol,
    double? taxRate,
    bool? taxIncluded,
    bool? darkMode,
    bool? pinEnabled,
    bool? biometricEnabled,
    bool? printReceiptAuto,
    String? receiptFooter,
    String? logoPath,
  }) {
    return AppSettings(
      businessName: businessName ?? this.businessName,
      businessAddress: businessAddress ?? this.businessAddress,
      businessPhone: businessPhone ?? this.businessPhone,
      businessEmail: businessEmail ?? this.businessEmail,
      currencySymbol: currencySymbol ?? this.currencySymbol,
      taxRate: taxRate ?? this.taxRate,
      taxIncluded: taxIncluded ?? this.taxIncluded,
      darkMode: darkMode ?? this.darkMode,
      pinEnabled: pinEnabled ?? this.pinEnabled,
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
      printReceiptAuto: printReceiptAuto ?? this.printReceiptAuto,
      receiptFooter: receiptFooter ?? this.receiptFooter,
      logoPath: logoPath ?? this.logoPath,
    );
  }
}
