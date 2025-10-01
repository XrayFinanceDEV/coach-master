enum TrainingAttendanceStatus {
  present,
  absent,
  late,
}

class TrainingAttendance {
  final String id;
  final String trainingId;
  final String playerId;
  final TrainingAttendanceStatus status;
  final String? reason;
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

  // JSON serialization for Firestore
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'trainingId': trainingId,
      'playerId': playerId,
      'status': status.name,
      'reason': reason,
      'arrivalTime': arrivalTime?.toIso8601String(),
    };
  }

  factory TrainingAttendance.fromJson(Map<String, dynamic> json) {
    return TrainingAttendance(
      id: json['id'] as String,
      trainingId: json['trainingId'] as String,
      playerId: json['playerId'] as String,
      status: TrainingAttendanceStatus.values.firstWhere((e) => e.name == json['status']),
      reason: json['reason'] as String?,
      arrivalTime: json['arrivalTime'] != null ? DateTime.parse(json['arrivalTime'] as String) : null,
    );
  }
}
