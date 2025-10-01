import 'package:coachmaster/models/training_attendance.dart';
import 'package:coachmaster/services/base_sync_repository.dart';

class TrainingAttendanceSyncRepository extends BaseSyncRepository<TrainingAttendance> {
  TrainingAttendanceSyncRepository({super.syncService})
    : super(
        boxName: 'trainingAttendances',
        entityType: 'trainingAttendances',
      );

  // Legacy methods for backward compatibility
  Future<void> init() async {
    if (!isInitialized) {
      throw Exception('TrainingAttendanceSyncRepository: Use initForUser() instead of init() for sync support');
    }
  }

  List<TrainingAttendance> getAttendances() => getAll();
  TrainingAttendance? getAttendance(String id) => get(id);

  // Enhanced methods with sync support
  Future<void> addAttendance(TrainingAttendance attendance) async {
    await addWithSync(attendance);
  }

  Future<void> updateAttendance(TrainingAttendance attendance) async {
    await updateWithSync(attendance);
  }

  Future<void> deleteAttendance(String id) async {
    await deleteWithSync(id);
  }

  // Additional query methods
  List<TrainingAttendance> getAttendancesForTraining(String trainingId) {
    return getAll().where((att) => att.trainingId == trainingId).toList();
  }

  List<TrainingAttendance> getAttendancesForPlayer(String playerId) {
    return getAll().where((att) => att.playerId == playerId).toList();
  }

  // Delete all attendances for a training (when training is deleted)
  Future<void> deleteAttendancesForTraining(String trainingId) async {
    final trainingAttendances = getAttendancesForTraining(trainingId);
    for (final attendance in trainingAttendances) {
      await deleteWithSync(attendance.id);
    }
  }

  // Implementation of abstract methods from BaseSyncRepository
  @override
  String getEntityId(TrainingAttendance item) => item.id;

  @override
  Map<String, dynamic> toMap(TrainingAttendance item) {
    return {
      'id': item.id,
      'trainingId': item.trainingId,
      'playerId': item.playerId,
      'status': item.status.name,
      'reason': item.reason,
      'arrivalTime': item.arrivalTime?.toIso8601String(),
    };
  }

  @override
  TrainingAttendance fromMap(Map<String, dynamic> map) {
    return TrainingAttendance(
      id: map['id'] as String,
      trainingId: map['trainingId'] as String,
      playerId: map['playerId'] as String,
      status: TrainingAttendanceStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => TrainingAttendanceStatus.present,
      ),
      reason: map['reason'] as String?,
      arrivalTime: map['arrivalTime'] != null
          ? DateTime.parse(map['arrivalTime'] as String)
          : null,
    );
  }
}
