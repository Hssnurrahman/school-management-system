import 'dart:convert';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../firebase_options.dart';
import '../models/user_model.dart';
import '../models/user_role.dart';
import 'database_service.dart';

String get _webApiKey => DefaultFirebaseOptions.web.apiKey;

bool get _isLinux => !kIsWeb && Platform.isLinux;

class AuthService extends ChangeNotifier {
  static const _effectiveRoleKey = 'effectiveRole';
  static const _loggedInKey = 'loggedInUserId';

  final _auth = FirebaseAuth.instance;

  UserModel? _currentUser;
  UserModel? get currentUser => _currentUser;
  UserRole? _effectiveRole;
  UserRole? get effectiveRole => _effectiveRole ?? _currentUser?.primaryRole;
  bool get hasMultipleRoles =>
      _currentUser != null && _currentUser!.additionalRoles.isNotEmpty;

  // ── Role switching ──────────────────────────────────────────────────────────

  Future<void> switchRole(UserRole role) async {
    if (_currentUser == null) return;
    if (role == _currentUser!.primaryRole ||
        _currentUser!.additionalRoles.contains(role)) {
      _effectiveRole = role;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_effectiveRoleKey, role.name);
      notifyListeners();
    }
  }

  Future<void> restoreEffectiveRole() async {
    if (_currentUser == null) return;
    final prefs = await SharedPreferences.getInstance();
    final roleName = prefs.getString(_effectiveRoleKey);
    if (roleName == null) return;
    UserRole? role;
    for (final r in UserRole.values) {
      if (r.name == roleName) {
        role = r;
        break;
      }
    }
    if (role == null) return;
    if (role == _currentUser!.primaryRole ||
        _currentUser!.additionalRoles.contains(role)) {
      _effectiveRole = role;
    }
  }

  // ── Session ─────────────────────────────────────────────────────────────────

  Future<UserModel?> restoreSession() async {
    String? uid;

    if (_isLinux) {
      // Linux: restore from SharedPreferences since Firebase Auth has no persistence
      final prefs = await SharedPreferences.getInstance();
      uid = prefs.getString(_loggedInKey);
    } else {
      uid = _auth.currentUser?.uid;
    }

    if (uid == null) return null;
    try {
      final users = await dbService.getUsers();
      final idx = users.indexWhere((u) => u.id == uid);
      if (idx == -1) return null;
      final user = users[idx];
      if (!user.isActive) return null;
      _currentUser = user;
      await restoreEffectiveRole();
      notifyListeners();
      return _currentUser;
    } catch (e) {
      debugPrint('restoreSession failed: $e');
      return null;
    }
  }

  Future<void> refreshCurrentUser() async {
    if (_currentUser == null) return;
    final users = await dbService.getUsers();
    final idx = users.indexWhere((u) => u.id == _currentUser!.id);
    if (idx == -1) return;
    final user = users[idx];
    if (user.isActive) {
      _currentUser = user;
      notifyListeners();
    }
  }

  // ── Login ───────────────────────────────────────────────────────────────────

  Future<Object?> login(String email, String password) async {
    try {
      final String uid;

      if (_isLinux) {
        uid = await _loginViaRest(email.trim().toLowerCase(), password);
      } else {
        final credential = await _auth.signInWithEmailAndPassword(
          email: email.trim().toLowerCase(),
          password: password,
        );
        uid = credential.user!.uid;
      }

      final users = await dbService.getUsers();
      final idx = users.indexWhere((u) => u.id == uid);
      if (idx == -1) {
        if (!_isLinux) await _auth.signOut();
        return 'Account not found. Please contact an administrator.';
      }
      final user = users[idx];

      if (!user.isActive) {
        if (!_isLinux) await _auth.signOut();
        return 'Your account is pending approval.';
      }
      if (user.primaryRole == UserRole.student ||
          user.primaryRole == UserRole.parent) {
        if (!_isLinux) await _auth.signOut();
        return 'Student & Parent portal coming soon.';
      }

      _currentUser = user;
      await restoreEffectiveRole();

      if (_isLinux) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_loggedInKey, uid);
      }

      notifyListeners();
      return user;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' ||
          e.code == 'wrong-password' ||
          e.code == 'invalid-credential') { return null; }
      return e.message ?? 'Login failed.';
    } catch (e) {
      final s = e.toString();
      if (s.contains('INVALID_PASSWORD') ||
          s.contains('EMAIL_NOT_FOUND') ||
          s.contains('INVALID_LOGIN_CREDENTIALS')) {
        return null;
      }
      debugPrint('Login failed: $e');
      return 'Login failed: $e';
    }
  }

  /// Firebase Auth REST API sign-in for Linux desktop.
  Future<String> _loginViaRest(String email, String password) async {
    final url = Uri.parse(
      'https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=$_webApiKey',
    );
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
        'returnSecureToken': true,
      }),
    );
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (data.containsKey('error')) {
      final msg = data['error']['message'] as String;
      throw Exception(msg);
    }
    return data['localId'] as String;
  }

  // ── Register ─────────────────────────────────────────────────────────────────

  Future<Object?> register({
    required String name,
    required String email,
    required String password,
    required UserRole role,
    String? phone,
    String? className,
    String? subject,
  }) async {
    try {
      final String uid;

      if (_isLinux) {
        uid = await _registerViaRest(email.trim().toLowerCase(), password);
      } else {
        final credential = await _auth.createUserWithEmailAndPassword(
          email: email.trim().toLowerCase(),
          password: password,
        );
        uid = credential.user!.uid;
      }

      final newUser = UserModel(
        id: uid,
        name: name,
        email: email.trim().toLowerCase(),
        primaryRole: role,
        isActive: true,
        phone: phone,
        className: role == UserRole.student ? className : null,
        subject: role == UserRole.teacher ? subject : null,
      );
      await dbService.insertUser(newUser);
      return newUser;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        return 'An account with this email already exists.';
      }
      return e.message ?? 'Registration failed.';
    } catch (e) {
      if (e.toString().contains('EMAIL_EXISTS')) {
        return 'An account with this email already exists.';
      }
      return 'Registration failed: $e';
    }
  }

  /// Firebase Auth REST API sign-up for Linux desktop.
  Future<String> _registerViaRest(String email, String password) async {
    final url = Uri.parse(
      'https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=$_webApiKey',
    );
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
        'returnSecureToken': true,
      }),
    );
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (data.containsKey('error')) {
      final msg = data['error']['message'] as String;
      throw Exception(msg);
    }
    return data['localId'] as String;
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────

  Future<bool> hasAdmin() async {
    return dbService.hasAnyAdmin();
  }

  Future<String?> resetPassword({required String email}) async {
    try {
      if (_isLinux) {
        await _sendPasswordResetViaRest(email.trim().toLowerCase());
      } else {
        await _auth.sendPasswordResetEmail(email: email.trim().toLowerCase());
      }
      return null;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') return 'No account found with that email.';
      return e.message ?? 'Failed to send reset email.';
    } catch (e) {
      return 'Failed to send reset email.';
    }
  }

  Future<void> _sendPasswordResetViaRest(String email) async {
    final url = Uri.parse(
      'https://identitytoolkit.googleapis.com/v1/accounts:sendOobCode?key=$_webApiKey',
    );
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'requestType': 'PASSWORD_RESET', 'email': email}),
    );
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final message =
        (body['error'] as Map?)?['message']?.toString() ?? 'UNKNOWN_ERROR';
    if (message.startsWith('EMAIL_NOT_FOUND')) {
      throw FirebaseAuthException(
          code: 'user-not-found',
          message: 'No account found with that email.');
    }
    throw FirebaseAuthException(code: 'reset-failed', message: message);
  }

  // ── Logout ───────────────────────────────────────────────────────────────────

  Future<void> logout() async {
    if (!_isLinux) await _auth.signOut();
    _currentUser = null;
    _effectiveRole = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_loggedInKey);
    await prefs.remove(_effectiveRoleKey);
    notifyListeners();
  }
}

final authService = AuthService();
