import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import 'package:flutter/foundation.dart';
import 'package:paynest/data/models/models.dart';
import 'package:paynest/data/datasources/remote/firebase_service.dart';

class FirestoreService {
  final FirebaseService _firebase = FirebaseService.instance;

  String? _businessId;
  String get businessId => _businessId ?? 'default_business';

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
  Future<void> recordSale(Transaction txn) async {
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
    });

    // Update inventory and create audit logs
    for (final item in txn.items) {
      final productDoc = _productsRef.doc(item.productId);
      batch.update(productDoc, {
        'stock_quantity': FieldValue.increment(-item.quantity),
      });

      final logDoc = _inventoryLogsRef.doc();
      batch.set(logDoc, {
        'productId': item.productId,
        'changeQuantity': -item.quantity,
        'reason': 'SALE',
        'saleId': txn.id,
        'receiptNumber': txn.receiptNumber,
        'timestamp': FieldValue.serverTimestamp(),
      });
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
}
