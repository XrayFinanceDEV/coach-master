import 'package:hive/hive.dart';

part 'training_attendance.g.dart';

enum TrainingAttendanceStatus {
  @HiveField(0)
  present,
  @HiveField(1)
  absent,
  @HiveField(2)
  late,
}

@HiveType(typeId: 5)
class TrainingAttendance {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String trainingId;
  @HiveField(2)
  final String playerId;
  @HiveField(3)
  final TrainingAttendanceStatus status;
  @HiveField(4)
  final String? reason;
  @HiveField(5)
  final DateTime? arrivalTime;

  TrainingAttendance({
    required this.id,
    required this.trainingId,
    required this.playerId,
    required this.status,
    this.reason,
    this.arrivalTime,
  });

  factory TrainingAttendance.create({
    required String trainingId,
    required String playerId,
    required TrainingAttendanceStatus status,
    String? reason,
    DateTime? arrivalTime,
  }) {
    return TrainingAttendance(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      trainingId: trainingId,
      playerId: playerId,
      status: status,
      reason: reason,
      arrivalTime: arrivalTime,
    );
  }
}
