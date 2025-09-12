import 'package:hive_flutter/hive_flutter.dart';
import 'package:coachmaster/models/training.dart';

class TrainingRepository {
  late Box<Training> _trainingBox;

  Future<void> init() async {
    _trainingBox = await Hive.openBox<Training>('trainings');
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
}
