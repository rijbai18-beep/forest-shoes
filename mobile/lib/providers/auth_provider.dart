import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../models/order_model.dart';
import '../services/auth_service.dart';
import '../services/audit_service.dart';
import '../services/notification_service.dart';

class AuthProvider extends ChangeNotifier {
  final _authService = AuthService();

  UserModel? _user;
  bool _isInitialized = false;
  String? _errorMessage;
  bool _isLoading = false;
  StreamSubscription? _userSub;

  UserModel? get user => _user;
  bool get isLoggedIn => _user != null;
  bool get isInitialized => _isInitialized;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;

  AuthProvider() {
    _init();
  }

  void _init() {
    _authService.authStateChanges.listen((firebaseUser) async {
      if (firebaseUser != null) {
        _userSub?.cancel();
        _userSub = _authService.userStream(firebaseUser.uid).listen((user) {
          _user = user;
          notifyListeners();
        });

        final token = await NotificationService.getToken();
        if (token != null) {
          await _authService.updateFcmToken(firebaseUser.uid, token);
        }
      } else {
        _userSub?.cancel();
        _user = null;
      }
      _isInitialized = true;
      notifyListeners();
    });
  }

  Future<bool> signIn(String email, String password) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      await _authService.signIn(email, password);
      AuditService.instance.logAction('user.login', details: {'email': email});
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _mapAuthError(e.code);
      AuditService.instance.logError(e, null, context: 'user.login_failed', details: {'email': email});
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> register({
    required String email,
    required String password,
    required String name,
    String? phone,
  }) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      await _authService.register(
        email: email,
        password: password,
        name: name,
        phone: phone,
      );
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _mapAuthError(e.code);
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signOut() async {
    if (_user != null) {
      AuditService.instance.logAction('user.logout', details: {'email': _user!.email});
      final token = await NotificationService.getToken();
      if (token != null) {
        await _authService.removeFcmToken(_user!.uid, token);
      }
    }
    await _authService.signOut();
  }

  Future<bool> sendPasswordReset(String email) async {
    try {
      await _authService.sendPasswordResetEmail(email);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    }
  }

  Future<bool> updateProfile(
      {String? name, String? phone, String? photoUrl}) async {
    if (_user == null) return false;
    _setLoading(true);
    try {
      await _authService.updateProfile(
          uid: _user!.uid, name: name, phone: phone, photoUrl: photoUrl);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateAddresses(List<AddressModel> addresses) async {
    if (_user == null) return false;
    try {
      await _authService.setAddresses(
        _user!.uid,
        addresses.map((a) => a.toMap()).toList(),
      );
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  String _mapAuthError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'email-already-in-use':
        return 'This email is already registered.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'invalid-email':
        return 'Invalid email address.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      default:
        return 'Authentication error. Please try again.';
    }
  }

  @override
  void dispose() {
    _userSub?.cancel();
    super.dispose();
  }
}
