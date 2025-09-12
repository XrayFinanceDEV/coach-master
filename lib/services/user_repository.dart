import 'package:hive/hive.dart';
import 'package:coachmaster/models/user.dart';

class UserRepository {
  late Box<User> _box;

  Future<void> init() async {
    _box = await Hive.openBox<User>('users');
  }

  Future<void> addUser(User user) async {
    await _box.put(user.email, user);
  }

  Future<void> updateUser(User user) async {
    await _box.put(user.email, user);
  }

  Future<void> deleteUser(String email) async {
    await _box.delete(email.toLowerCase().trim());
  }

  User? getUserByEmail(String email) {
    return _box.get(email.toLowerCase().trim());
  }

  List<User> getAllUsers() {
    return _box.values.toList();
  }

  bool get isEmpty => _box.isEmpty;
  int get length => _box.length;

  Future<void> clearAll() async {
    await _box.clear();
  }
}