import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import 'package:flutter/foundation.dart';
import 'package:paynest/data/models/models.dart';
import 'package:paynest/data/datasources/remote/firebase_service.dart';

class FirestoreService {
  final FirebaseService _firebase = FirebaseService.instance;

  String? _businessId;
  String get businessId => _businessId ?? 'paynest_main_store';

  void setBusinessId(String id) {
    _businessId = id;
  }

  DocumentReference<Map<String, dynamic>> get _businessDoc =>
      _firebase.firestore.collection('businesses').doc(businessId);

  CollectionReference<Map<String, dynamic>> get _productsRef =>
      _businessDoc.collection('products');

  CollectionReference<Map<String, dynamic>> get _customersRef =>
      _businessDoc.collection('customers');

  CollectionReference<Map<String, dynamic>> get _salesRef =>
      _businessDoc.collection('sales');

  CollectionReference<Map<String, dynamic>> get _inventoryLogsRef =>
      _businessDoc.collection('inventory_logs');

  /// Ensure root business document and owner membership exist to satisfy security rules
  Future<void> ensureBusinessInitialized() async {
    if (!_firebase.isInitialized) return;
    final user = _firebase.currentUser;

    try {
      await _businessDoc.set({
        'name': 'PayNest POS',
        'ownerId': user?.uid ?? 'anonymous',
        'currency': 'UGX',
        'country': 'Uganda',
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (user != null) {
        await _businessDoc.collection('members').doc(user.uid).set({
          'role': 'owner',
          'email': user.email ?? '',
          'addedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    } catch (e) {
      debugPrint('[FirestoreService] Note initializing business: $e');
    }
  }

  // Products
  Stream<List<Product>> streamProducts() {
    if (!_firebase.isInitialized) return const Stream.empty();
    return _productsRef
        .where('is_active', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return Product(
          id: doc.id,
          name: data['name'] ?? '',
          description: data['description'],
          category: data['category'] ?? 'other',
          price: (data['price'] as num?)?.toDouble() ?? 0.0,
          costPrice: (data['cost_price'] as num?)?.toDouble(),
          stockQuantity: (data['stock_quantity'] as num?)?.toInt() ?? 0,
          sku: data['sku'],
          barcode: data['barcode'],
          imageUrl: data['image_url'],
          isActive: data['is_active'] ?? true,
          trackInventory: data['track_inventory'] ?? true,
          taxRate: (data['tax_rate'] as num?)?.toDouble() ?? 18.0,
          createdAt: (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
          updatedAt: (data['updated_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
        );
      }).toList();
    });
  }

  Future<void> upsertProduct(Product product) async {
    if (!_firebase.isInitialized) return;
    await _productsRef.doc(product.id).set({
      'name': product.name,
      'description': product.description,
      'category': product.category,
      'price': product.price,
      'cost_price': product.costPrice,
      'stock_quantity': product.stockQuantity,
      'sku': product.sku,
      'barcode': product.barcode,
      'image_url': product.imageUrl,
      'is_active': product.isActive,
      'track_inventory': product.trackInventory,
      'tax_rate': product.taxRate ?? 18.0,
      'updated_at': FieldValue.serverTimestamp(),
      'created_at': Timestamp.fromDate(product.createdAt),
    }, SetOptions(merge: true));
  }

  // Customers
  Stream<List<Customer>> streamCustomers() {
    if (!_firebase.isInitialized) return const Stream.empty();
    return _customersRef.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return Customer(
          id: doc.id,
          name: data['name'] ?? '',
          email: data['email'],
          phone: data['phone'],
          address: data['address'],
          totalSpent: (data['total_spent'] as num?)?.toDouble() ?? 0.0,
          totalOrders: (data['total_orders'] as num?)?.toInt() ?? 0,
          notes: data['notes'],
          createdAt: (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
          lastVisit: (data['last_visit'] as Timestamp?)?.toDate(),
          loyaltyPoints: (data['loyalty_points'] as num?)?.toDouble() ?? 0.0,
        );
      }).toList();
    });
  }

  Future<void> upsertCustomer(Customer customer) async {
    if (!_firebase.isInitialized) return;
    await _customersRef.doc(customer.id).set({
      'name': customer.name,
      'email': customer.email,
      'phone': customer.phone,
      'address': customer.address,
      'total_spent': customer.totalSpent,
      'total_orders': customer.totalOrders,
      'notes': customer.notes,
      'loyalty_points': customer.loyaltyPoints,
      'last_visit': customer.lastVisit != null ? Timestamp.fromDate(customer.lastVisit!) : null,
      'created_at': Timestamp.fromDate(customer.createdAt),
    }, SetOptions(merge: true));
  }

  // Sales & Inventory Decrements
  Future<void> recordSale(Transaction txn, {bool updateStockInFirestore = true}) async {
    if (!_firebase.isInitialized) return;

    final batch = _firebase.firestore.batch();
    final saleDoc = _salesRef.doc(txn.id);

    final itemsData = txn.items.map((i) => {
      'productId': i.productId,
      'productName': i.productName,
      'price': i.price,
      'quantity': i.quantity,
      'discountPercent': i.discountPercent,
      'total': i.total,
    }).toList();

    batch.set(saleDoc, {
      'receiptNumber': txn.receiptNumber,
      'subtotal': txn.subtotal,
      'taxAmount': txn.taxAmount,
      'discountAmount': txn.discountAmount,
      'total': txn.total,
      'amountPaid': txn.amountPaid,
      'change': txn.change,
      'paymentMethod': txn.paymentMethod,
      'status': txn.status,
      'type': txn.type,
      'customerId': txn.customerId,
      'customerName': txn.customerName,
      'notes': txn.notes,
      'items': itemsData,
      'isOfflineCreated': !txn.isSynced,
      'deviceTimestamp': Timestamp.fromDate(txn.createdAt),
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // Update inventory and create audit logs only if requested
    if (updateStockInFirestore) {
      for (final item in txn.items) {
        final productDoc = _productsRef.doc(item.productId);
        batch.update(productDoc, {
          'stock_quantity': FieldValue.increment(-item.quantity),
        });

        // Use deterministic log document ID to avoid duplicate deductions on retry
        final logDoc = _inventoryLogsRef.doc('${txn.id}_${item.productId}');
        batch.set(logDoc, {
          'productId': item.productId,
          'changeQuantity': -item.quantity,
          'reason': 'SALE',
          'saleId': txn.id,
          'receiptNumber': txn.receiptNumber,
          'timestamp': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    }

    // Update customer stats if linked
    if (txn.customerId != null && txn.customerId!.isNotEmpty) {
      final customerDoc = _customersRef.doc(txn.customerId);
      batch.set(customerDoc, {
        'total_spent': FieldValue.increment(txn.total),
        'total_orders': FieldValue.increment(1),
        'last_visit': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

    await batch.commit();
    debugPrint('Sale ${txn.receiptNumber} committed to Firestore');
  }

  // Batch Sync for Multiple Offline Transactions
  Future<List<String>> syncPendingTransactions(List<Transaction> pendingTxns) async {
    if (!_firebase.isInitialized || pendingTxns.isEmpty) return [];

    final syncedIds = <String>[];
    for (final txn in pendingTxns) {
      try {
        await recordSale(txn);
        syncedIds.add(txn.id);
      } catch (e) {
        debugPrint('Error syncing txn ${txn.id}: $e');
      }
    }
    return syncedIds;
  }

  /// Bulk sync all local SQLite products, customers and sales directly to Firestore
  Future<int> syncAllLocalDataToFirestore({
    required List<Product> products,
    required List<Customer> customers,
    required List<Transaction> transactions,
  }) async {
    if (!_firebase.isInitialized) {
      debugPrint('[FirestoreService] Firebase is not initialized. Skipping cloud sync.');
      return 0;
    }

    await ensureBusinessInitialized();
    int syncedCount = 0;

    WriteBatch batch = _firebase.firestore.batch();
    int opCount = 0;

    Future<void> commitBatchIfNeeded({bool force = false}) async {
      if (opCount > 0 && (opCount >= 250 || force)) {
        await batch.commit();
        batch = _firebase.firestore.batch();
        opCount = 0;
      }
    }

    // 1. Sync all products to Firestore in batches
    for (final product in products) {
      try {
        final doc = _productsRef.doc(product.id);
        batch.set(doc, {
          'name': product.name,
          'description': product.description,
          'category': product.category,
          'price': product.price,
          'cost_price': product.costPrice,
          'stock_quantity': product.stockQuantity,
          'sku': product.sku,
          'barcode': product.barcode,
          'is_active': product.isActive,
          'track_inventory': product.trackInventory,
          'tax_rate': product.taxRate ?? 18.0,
          'updated_at': FieldValue.serverTimestamp(),
          'created_at': Timestamp.fromDate(product.createdAt),
        }, SetOptions(merge: true));
        opCount++;
        syncedCount++;
        await commitBatchIfNeeded();
      } catch (e) {
        debugPrint('[FirestoreService] Error batching product ${product.id}: $e');
      }
    }

    // 2. Sync all customers to Firestore in batches
    for (final customer in customers) {
      try {
        final doc = _customersRef.doc(customer.id);
        batch.set(doc, {
          'name': customer.name,
          'email': customer.email,
          'phone': customer.phone,
          'address': customer.address,
          'total_spent': customer.totalSpent,
          'total_orders': customer.totalOrders,
          'notes': customer.notes,
          'loyalty_points': customer.loyaltyPoints,
          'last_visit': customer.lastVisit != null ? Timestamp.fromDate(customer.lastVisit!) : null,
          'created_at': Timestamp.fromDate(customer.createdAt),
        }, SetOptions(merge: true));
        opCount++;
        syncedCount++;
        await commitBatchIfNeeded();
      } catch (e) {
        debugPrint('[FirestoreService] Error batching customer ${customer.id}: $e');
      }
    }

    // 3. Sync all transactions to Firestore in batches
    for (final txn in transactions) {
      try {
        final doc = _salesRef.doc(txn.id);
        final itemsData = txn.items.map((i) => {
          'productId': i.productId,
          'productName': i.productName,
          'price': i.price,
          'quantity': i.quantity,
          'discountPercent': i.discountPercent,
          'total': i.total,
        }).toList();

        batch.set(doc, {
          'id': txn.id,
          'receiptNumber': txn.receiptNumber,
          'subtotal': txn.subtotal,
          'taxAmount': txn.taxAmount,
          'discountAmount': txn.discountAmount,
          'total': txn.total,
          'amountPaid': txn.amountPaid,
          'change': txn.change,
          'paymentMethod': txn.paymentMethod,
          'status': txn.status,
          'type': txn.type,
          'customerId': txn.customerId,
          'customerName': txn.customerName,
          'items': itemsData,
          'itemCount': txn.items.length,
          'timestamp': Timestamp.fromDate(txn.createdAt),
        }, SetOptions(merge: true));
        opCount++;
        syncedCount++;
        await commitBatchIfNeeded();
      } catch (e) {
        debugPrint('[FirestoreService] Error batching transaction ${txn.id}: $e');
      }
    }

    await commitBatchIfNeeded(force: true);

    debugPrint('[FirestoreService] Successfully pushed $syncedCount items to Firestore in batches.');
    return syncedCount;
  }
}
