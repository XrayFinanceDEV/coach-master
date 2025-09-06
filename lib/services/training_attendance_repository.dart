import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coachmaster/models/training_attendance.dart';

class TrainingAttendanceRepository {
  late Box<TrainingAttendance> _attendanceBox;

  Future<void> init() async {
    _attendanceBox = await Hive.openBox<TrainingAttendance>('trainingAttendances');
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
}

final trainingAttendanceRepositoryProvider = Provider((ref) => TrainingAttendanceRepository());
