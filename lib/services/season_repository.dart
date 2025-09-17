import 'package:hive_flutter/hive_flutter.dart';
import 'package:coachmaster/models/season.dart';
import 'package:flutter/foundation.dart';

class SeasonRepository {
  late Box<Season> _seasonBox;
  String? _currentUserId;

  Future<void> init({String? userId}) async {
    _currentUserId = userId;
    // Use user-specific box to prevent cross-user data conflicts
    final boxName = userId != null ? 'seasons_$userId' : 'seasons';
    _seasonBox = await Hive.openBox<Season>(boxName);
    
    if (kDebugMode) {
      print('🔷 SeasonRepository: Initialized with box $boxName');
    }
  }

  List<Season> getSeasons() {
    return _seasonBox.values.toList();
  }

  Season? getSeason(String id) {
    return _seasonBox.get(id);
  }

  Future<void> addSeason(Season season) async {
    await _seasonBox.put(season.id, season);
  }

  Future<void> updateSeason(Season season) async {
    await _seasonBox.put(season.id, season);
  }

  Future<void> deleteSeason(String id) async {
    await _seasonBox.delete(id);
  }

  /// Close the current box (useful for user switching)
  Future<void> close() async {
    try {
      await _seasonBox.close();
      if (kDebugMode) {
        print('🔷 SeasonRepository: Closed');
      }
    } catch (e) {
      if (kDebugMode) {
        print('🔷 SeasonRepository: Error closing box: $e');
      }
    }
  }
}