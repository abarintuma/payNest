import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:paynest/data/datasources/remote/firebase_service.dart';
import 'package:paynest/data/datasources/remote/firestore_service.dart';
import 'package:paynest/data/datasources/remote/sync_service.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  final FirebaseService _firebase = FirebaseService.instance;
  final FirestoreService _firestoreService = FirestoreService();

  AuthStatus _status = AuthStatus.unknown;
  User? _user;
  String? _error;
  bool _isLoading = false;

  StreamSubscription<User?>? _authSubscription;

  AuthStatus get status => _status;
  User? get user => _user;
  String? get error => _error;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isFirebaseAvailable => _firebase.isInitialized;

  AuthProvider() {
    _init();
  }

  void _init() {
    if (!_firebase.isInitialized) {
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return;
    }

    _authSubscription = _firebase.authStateChanges.listen((user) {
      _user = user;
      if (user != null) {
        _status = AuthStatus.authenticated;
        _firestoreService.setBusinessId(user.uid);
        SyncService.instance.startListening();
      } else {
        _status = AuthStatus.unauthenticated;
      }
      notifyListeners();
    });
  }

  Future<bool> signIn(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final cred = await _firebase.signInWithEmail(email, password);
      if (cred == null) {
        _error = 'Firebase is not available. Running in offline mode.';
        _isLoading = false;
        notifyListeners();
        return false;
      }
      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _error = _mapAuthError(e.code);
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Sign in failed: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register(String email, String password, String businessName) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final cred = await _firebase.registerWithEmail(email, password);
      if (cred == null) {
        _error = 'Firebase is not available. Running in offline mode.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Update display name
      await cred.user?.updateDisplayName(businessName);
      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _error = _mapAuthError(e.code);
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Registration failed: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    await _firebase.signOut();
    _user = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  Future<void> sendPasswordReset(String email) async {
    if (!_firebase.isInitialized) return;
    await _firebase.auth.sendPasswordResetEmail(email: email.trim());
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  String _mapAuthError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found with that email.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'email-already-in-use':
        return 'An account already exists with that email.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait and try again.';
      case 'network-request-failed':
        return 'Network error. Check your connection.';
      case 'invalid-credential':
        return 'Invalid email or password.';
      default:
        return 'Authentication failed ($code). Please try again.';
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
