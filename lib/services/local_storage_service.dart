import 'package:hive_flutter/hive_flutter.dart';

class LocalStorageService {
  Future<Box<T>> openBox<T>(String name) async {
    return await Hive.openBox<T>(name);
  }

  Future<void> put<T>(String boxName, String key, T value) async {
    final box = await openBox<T>(boxName);
    await box.put(key, value);
  }

  Future<T?> get<T>(String boxName, String key) async {
    final box = await openBox<T>(boxName);
    return box.get(key);
  }

  Future<void> delete<T>(String boxName, String key) async {
    final box = await openBox<T>(boxName);
    await box.delete(key);
  }

  Future<void> closeBox<T>(String name) async {
    await Hive.box<T>(name).close();
  }
}
