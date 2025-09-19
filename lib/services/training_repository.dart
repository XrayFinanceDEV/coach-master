import 'package:hive_flutter/hive_flutter.dart';
import 'package:coachmaster/models/training.dart';
import 'package:flutter/foundation.dart';

class TrainingRepository {
  late Box<Training> _trainingBox;

  Future<void> init({String? userId}) async {
    // Use user-specific box to prevent cross-user data conflicts
    final boxName = userId != null ? 'trainings_$userId' : 'trainings';
    _trainingBox = await Hive.openBox<Training>(boxName);
    
    if (kDebugMode) {
      print('🟪 TrainingRepository: Initialized with box $boxName');
    }
  }

  List<Training> getTrainings() {
    return _trainingBox.values.toList();
  }

  Training? getTraining(String id) {
    return _trainingBox.get(id);
  }

  Future<void> addTraining(Training training) async {
    await _trainingBox.put(training.id, training);
  }

  Future<void> updateTraining(Training training) async {
    await _trainingBox.put(training.id, training);
  }

  Future<void> deleteTraining(String id) async {
    await _trainingBox.delete(id);
  }

  List<Training> getTrainingsForTeam(String teamId) {
    return _trainingBox.values.where((training) => training.teamId == teamId).toList();
  }

  /// Close the current box (useful for user switching)
  Future<void> close() async {
    try {
      await _trainingBox.close();
      if (kDebugMode) {
        print('🟪 TrainingRepository: Closed');
      }
    } catch (e) {
      if (kDebugMode) {
        print('🟪 TrainingRepository: Error closing box: $e');
      }
    }
  }
}
