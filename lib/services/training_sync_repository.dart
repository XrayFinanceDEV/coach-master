import 'package:flutter/material.dart';
import 'package:coachmaster/models/training.dart';
import 'package:coachmaster/services/base_sync_repository.dart';
import 'package:coachmaster/services/firestore_sync_service.dart';

class TrainingSyncRepository extends BaseSyncRepository<Training> {
  TrainingSyncRepository({FirestoreSyncService? syncService}) 
    : super(
        boxName: 'trainings',
        entityType: 'trainings',
        syncService: syncService,
      );

  // Legacy methods for backward compatibility
  Future<void> init() async {
    if (!isInitialized) {
      throw Exception('TrainingSyncRepository: Use initForUser() instead of init() for sync support');
    }
  }

  List<Training> getTrainings() => getAll();
  Training? getTraining(String id) => get(id);

  // Enhanced methods with sync support
  Future<void> addTraining(Training training) async {
    await addWithSync(training);
  }

  Future<void> updateTraining(Training training) async {
    await updateWithSync(training);
  }

  Future<void> deleteTraining(String id) async {
    await deleteWithSync(id);
  }

  // Additional query methods
  List<Training> getTrainingsForTeam(String teamId) {
    return getAll().where((training) => training.teamId == teamId).toList();
  }

  List<Training> getTrainingsByDate(DateTime date) {
    return getAll().where((training) => 
      training.date.year == date.year &&
      training.date.month == date.month &&
      training.date.day == date.day
    ).toList();
  }

  List<Training> getTrainingsForWeek(DateTime startOfWeek) {
    final endOfWeek = startOfWeek.add(const Duration(days: 7));
    return getAll().where((training) => 
      training.date.isAfter(startOfWeek.subtract(const Duration(days: 1))) &&
      training.date.isBefore(endOfWeek)
    ).toList();
  }

  List<Training> getUpcomingTrainings({int limit = 10}) {
    final now = DateTime.now();
    final upcoming = getAll().where((training) => training.date.isAfter(now)).toList();
    upcoming.sort((a, b) => a.date.compareTo(b.date));
    return upcoming.take(limit).toList();
  }

  // Implementation of abstract methods from BaseSyncRepository
  @override
  String getEntityId(Training item) => item.id;

  @override
  Map<String, dynamic> toMap(Training item) {
    return {
      'id': item.id,
      'teamId': item.teamId,
      'date': item.date.toIso8601String(),
      'startTime': '${item.startTime.hour}:${item.startTime.minute}',
      'endTime': '${item.endTime.hour}:${item.endTime.minute}',
      'location': item.location,
      'objectives': item.objectives,
      'coachNotes': item.coachNotes,
    };
  }

  @override
  Training fromMap(Map<String, dynamic> map) {
    // Parse time strings back to TimeOfDay
    final startTimeParts = (map['startTime'] as String).split(':');
    final endTimeParts = (map['endTime'] as String).split(':');
    
    return Training(
      id: map['id'] as String,
      teamId: map['teamId'] as String,
      date: DateTime.parse(map['date'] as String),
      startTime: TimeOfDay(
        hour: int.parse(startTimeParts[0]),
        minute: int.parse(startTimeParts[1]),
      ),
      endTime: TimeOfDay(
        hour: int.parse(endTimeParts[0]),
        minute: int.parse(endTimeParts[1]),
      ),
      location: map['location'] as String,
      objectives: List<String>.from(map['objectives'] as List),
      coachNotes: map['coachNotes'] as String?,
    );
  }
}