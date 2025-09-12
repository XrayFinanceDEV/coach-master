import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:hive/hive.dart';
import 'package:coachmaster/models/user.dart';

class AuthService {
  late Box<User> _userBox;
  late Box<String> _sessionBox;

  Future<void> init() async {
    _userBox = await Hive.openBox<User>('users');
    _sessionBox = await Hive.openBox<String>('session');
  }

  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }


  Future<User?> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      // Check if user already exists
      final existingUser = await getUserByEmail(email);
      if (existingUser != null) {
        throw Exception('User with this email already exists');
      }

      final passwordHash = _hashPassword(password);
      final user = User.create(
        name: name,
        email: email.toLowerCase().trim(),
        passwordHash: passwordHash,
      );

      await _userBox.put(user.email, user);
      await _setCurrentSession(user);
      
      return user;
    } catch (e) {
      throw Exception('Registration failed: $e');
    }
  }

  Future<User?> login({
    required String email,
    required String password,
  }) async {
    try {
      final user = await getUserByEmail(email);
      
      if (user == null) {
        throw Exception('User not found');
      }

      final passwordHash = _hashPassword(password);
      if (user.passwordHash != passwordHash) {
        throw Exception('Invalid password');
      }

      await _setCurrentSession(user);
      return user;
    } catch (e) {
      throw Exception('Login failed: $e');
    }
  }

  Future<void> logout() async {
    await _sessionBox.clear();
  }

  Future<User?> getCurrentUser() async {
    try {
      final currentEmail = _sessionBox.get('current_user_email');
      if (currentEmail == null) {
        return null;
      }
      
      final user = await getUserByEmail(currentEmail);
      return user;
    } catch (e) {
      return null;
    }
  }

  Future<User?> getUserByEmail(String email) async {
    return _userBox.get(email.toLowerCase().trim());
  }

  Future<void> updateUser(User user) async {
    await _userBox.put(user.email, user);
    
    // Update session if this is the current user
    final currentEmail = _sessionBox.get('current_user_email');
    if (currentEmail == user.email) {
      await _setCurrentSession(user);
    }
  }

  Future<bool> isUserLoggedIn() async {
    final currentUser = await getCurrentUser();
    return currentUser != null;
  }

  Future<void> _setCurrentSession(User user) async {
    await _sessionBox.put('current_user_email', user.email);
  }

  List<User> getAllUsers() {
    return _userBox.values.toList();
  }

  Future<void> deleteUser(String email) async {
    await _userBox.delete(email.toLowerCase().trim());
    
    // Clear session if deleting current user
    final currentEmail = _sessionBox.get('current_user_email');
    if (currentEmail == email.toLowerCase().trim()) {
      await logout();
    }
  }

  // Debug function to inspect database contents
  void debugDatabase() {
    // Debug functionality removed for production
  }

  // Clear all user data and sessions
  Future<void> clearAllData() async {
    try {
      // Clear authentication boxes
      await _userBox.clear();
      await _sessionBox.clear();
      
      // Clear all application data boxes
      final boxesToClear = [
        'users',
        'seasons',
        'teams',
        'players',
        'trainings',
        'trainingAttendances',
        'matches',
        'matchConvocations',
        'matchStatistics',
        'notes',
        'onboardingSettings',
      ];
      
      for (final boxName in boxesToClear) {
        try {
          if (Hive.isBoxOpen(boxName)) {
            final box = Hive.box(boxName);
            await box.clear();
          } else {
            // Open and clear the box if it exists
            try {
              final box = await Hive.openBox(boxName);
              await box.clear();
              await box.close();
            } catch (e) {
              // Box not found or error clearing, continue
            }
          }
        } catch (e) {
          // Error clearing box, continue with others
        }
      }
    } catch (e) {
      rethrow;
    }
  }
}