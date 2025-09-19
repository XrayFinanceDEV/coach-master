import 'package:hive_flutter/hive_flutter.dart';
import 'package:coachmaster/models/training_attendance.dart';

class TrainingAttendanceRepository {
  late Box<TrainingAttendance> _attendanceBox;

  Future<void> init({String? userId}) async {
    final boxName = userId != null ? 'trainingAttendances_$userId' : 'trainingAttendances';
    _attendanceBox = await Hive.openBox<TrainingAttendance>(boxName);
  }

  List<TrainingAttendance> getAttendances() {
    return _attendanceBox.values.toList();
  }

  TrainingAttendance? getAttendance(String id) {
    return _attendanceBox.get(id);
  }

  Future<void> addAttendance(TrainingAttendance attendance) async {
    await _attendanceBox.put(attendance.id, attendance);
  }

  Future<void> updateAttendance(TrainingAttendance attendance) async {
    await _attendanceBox.put(attendance.id, attendance);
  }

  Future<void> deleteAttendance(String id) async {
    await _attendanceBox.delete(id);
  }

  List<TrainingAttendance> getAttendancesForTraining(String trainingId) {
    return _attendanceBox.values.where((att) => att.trainingId == trainingId).toList();
  }

  List<TrainingAttendance> getAttendancesForPlayer(String playerId) {
    return _attendanceBox.values.where((att) => att.playerId == playerId).toList();
  }

  // Delete all attendances for a training (when training is deleted)
  Future<void> deleteAttendancesForTraining(String trainingId) async {
    final trainingAttendances = getAttendancesForTraining(trainingId);
    for (final attendance in trainingAttendances) {
      await _attendanceBox.delete(attendance.id);
    }
  }
}
