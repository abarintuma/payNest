import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class FirebaseService {
  static final FirebaseService instance = FirebaseService._init();
  FirebaseService._init();

  FirebaseAuth? _auth;
  FirebaseFirestore? _firestore;
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;
  FirebaseAuth get auth => _auth ?? FirebaseAuth.instance;
  FirebaseFirestore get firestore => _firestore ?? FirebaseFirestore.instance;

  User? get currentUser => _isInitialized ? auth.currentUser : null;
  Stream<User?> get authStateChanges =>
      _isInitialized ? auth.authStateChanges() : const Stream.empty();

  /// Initialize Firebase with offline caching enabled
  Future<bool> initialize({FirebaseOptions? options}) async {
    try {
      if (Firebase.apps.isNotEmpty) {
        _isInitialized = true;
        _setupServices();
        return true;
      }

      if (options != null) {
        await Firebase.initializeApp(options: options);
      } else if (kIsWeb) {
        await Firebase.initializeApp(
          options: const FirebaseOptions(
            apiKey: 'AIzaSyAZytHoe4T_KC7KjaX2aKW12gakrD0rSr0',
            appId: '1:983099985598:web:paynest',
            messagingSenderId: '983099985598',
            projectId: 'paynest-38428',
            authDomain: 'paynest-38428.firebaseapp.com',
            storageBucket: 'paynest-38428.firebasestorage.app',
          ),
        );
      } else {
        await Firebase.initializeApp();
      }

      _isInitialized = true;
      _setupServices();
      debugPrint('PayNest Firebase initialized successfully');
      return true;
    } catch (e) {
      debugPrint('Firebase initialization warning (running in offline/local mode): $e');
      _isInitialized = false;
      return false;
    }
  }

  void _setupServices() {
    _auth = FirebaseAuth.instance;
    _firestore = FirebaseFirestore.instance;

    // Enable offline persistence for Firestore
    try {
      _firestore!.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );
    } catch (e) {
      debugPrint('Firestore settings note: $e');
    }
  }

  // Auth Operations
  Future<UserCredential?> signInWithEmail(String email, String password) async {
    if (!_isInitialized) return null;
    return await auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );
  }

  Future<UserCredential?> registerWithEmail(String email, String password) async {
    if (!_isInitialized) return null;
    return await auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );
  }

  Future<void> signOut() async {
    if (_isInitialized) {
      await auth.signOut();
    }
  }
}
