import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:paynest/data/datasources/remote/firebase_service.dart';
import 'package:paynest/data/datasources/remote/firestore_service.dart';
import 'package:paynest/data/repositories/repositories.dart';

class SyncService {
  static final SyncService instance = SyncService._internal();
  SyncService._internal();

  final Connectivity _connectivity = Connectivity();
  final TransactionRepository _transactionRepo = TransactionRepository();
  final ProductRepository _productRepo = ProductRepository();
  final CustomerRepository _customerRepo = CustomerRepository();
  final FirestoreService _firestoreService = FirestoreService();

  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  StreamSubscription? _productSubscription;
  StreamSubscription? _customerSubscription;

  final ValueNotifier<bool> isOnlineNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<bool> isSyncingNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<int> pendingSyncCountNotifier = ValueNotifier<int>(0);
  final ValueNotifier<DateTime?> lastSyncTimeNotifier = ValueNotifier<DateTime?>(null);

  bool get isOnline => isOnlineNotifier.value;
  bool get isSyncing => isSyncingNotifier.value;
  int get pendingSyncCount => pendingSyncCountNotifier.value;
  DateTime? get lastSyncTime => lastSyncTimeNotifier.value;

  /// Start background connectivity listener and sync loops
  void startListening() {
    _connectivitySubscription?.cancel();

    // Check initial connectivity
    _checkInitialConnectivity();

    // Listen to network transitions
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((results) {
      final online = results.any((r) => r != ConnectivityResult.none);
      isOnlineNotifier.value = online;
      debugPrint('[SyncService] Connectivity changed: online=$online');
      if (online) {
        syncPendingTransactions();
      }
    });

    // Check pending count initially
    updatePendingCount();

    // Subscribe to remote updates if Firebase is initialized
    _subscribeToRemoteStreams();
  }

  Future<void> _checkInitialConnectivity() async {
    try {
      final results = await _connectivity.checkConnectivity();
      final online = results.any((r) => r != ConnectivityResult.none);
      isOnlineNotifier.value = online;
      if (online) {
        syncPendingTransactions();
      }
    } catch (e) {
      debugPrint('[SyncService] Connectivity check note: $e');
    }
  }

  void _subscribeToRemoteStreams() {
    if (!FirebaseService.instance.isInitialized) return;

    // Listen to remote products and update local cache
    _productSubscription?.cancel();
    _productSubscription = _firestoreService.streamProducts().listen((products) async {
      for (final product in products) {
        try {
          await _productRepo.saveProductFromRemote(product);
        } catch (e) {
          debugPrint('[SyncService] Error saving remote product: $e');
        }
      }
    }, onError: (err) {
      debugPrint('[SyncService] Product stream error: $err');
    });

    // Listen to remote customers and update local cache
    _customerSubscription?.cancel();
    _customerSubscription = _firestoreService.streamCustomers().listen((customers) async {
      for (final customer in customers) {
        try {
          await _customerRepo.saveCustomerFromRemote(customer);
        } catch (e) {
          debugPrint('[SyncService] Error saving remote customer: $e');
        }
      }
    }, onError: (err) {
      debugPrint('[SyncService] Customer stream error: $err');
    });
  }

  /// Recalculate pending transactions in local SQLite
  Future<void> updatePendingCount() async {
    try {
      final unsynced = await _transactionRepo.getUnsyncedTransactions();
      pendingSyncCountNotifier.value = unsynced.length;
    } catch (e) {
      debugPrint('[SyncService] Error updating pending count: $e');
    }
  }

  /// Synchronize all offline transactions to Firestore
  Future<void> syncPendingTransactions() async {
    if (isSyncingNotifier.value) return;

    final hasFirebase = FirebaseService.instance.isInitialized;
    if (!hasFirebase) {
      await updatePendingCount();
      return;
    }

    try {
      final pending = await _transactionRepo.getUnsyncedTransactions();
      if (pending.isEmpty) {
        pendingSyncCountNotifier.value = 0;
        return;
      }

      isSyncingNotifier.value = true;
      debugPrint('[SyncService] Syncing ${pending.length} pending offline sales...');

      final syncedIds = await _firestoreService.syncPendingTransactions(pending);
      for (final id in syncedIds) {
        await _transactionRepo.markAsSynced(id);
      }

      final remaining = await _transactionRepo.getUnsyncedTransactions();
      pendingSyncCountNotifier.value = remaining.length;
      lastSyncTimeNotifier.value = DateTime.now();
      debugPrint('[SyncService] Sync completed. ${syncedIds.length} synced, ${remaining.length} remaining.');
    } catch (e) {
      debugPrint('[SyncService] Sync failed with error: $e');
    } finally {
      isSyncingNotifier.value = false;
    }
  }

  void dispose() {
    _connectivitySubscription?.cancel();
    _productSubscription?.cancel();
    _customerSubscription?.cancel();
    isOnlineNotifier.dispose();
    isSyncingNotifier.dispose();
    pendingSyncCountNotifier.dispose();
    lastSyncTimeNotifier.dispose();
  }
}
