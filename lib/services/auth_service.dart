import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../models/user_role.dart';
import 'database_service.dart';

class AuthService {
  static const _loggedInKey = 'loggedInUserId';

  UserModel? _currentUser;
  UserModel? get currentUser => _currentUser;

  /// Try to restore session from shared_preferences
  Future<UserModel?> restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString(_loggedInKey);
    if (id == null) return null;
    final users = await dbService.getUsers();
    try {
      _currentUser = users.firstWhere((u) => u.id == id);
      return _currentUser;
    } catch (_) {
      return null;
    }
  }

  Future<UserModel?> login(String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 600));
    final users = await dbService.getUsers();
    try {
      final user = users.firstWhere(
        (u) => u.email.toLowerCase() == email.toLowerCase().trim(),
      );
      _currentUser = user;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_loggedInKey, user.id);
      return user;
    } catch (_) {
      return null;
    }
  }

  Future<void> logout() async {
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_loggedInKey);
  }

  // Fallback mock users (used before DB is ready)
  static List<UserModel> get mockUsers => [
        UserModel(id: '1', name: 'Admin User', email: 'admin@school.com', role: UserRole.admin),
        UserModel(id: '2', name: 'John Teacher', email: 'teacher@school.com', role: UserRole.teacher),
        UserModel(id: '3', name: 'Alice Student', email: 'student@school.com', role: UserRole.student),
        UserModel(id: '4', name: 'Parent User', email: 'parent@school.com', role: UserRole.parent),
      ];
}

final authService = AuthService();
