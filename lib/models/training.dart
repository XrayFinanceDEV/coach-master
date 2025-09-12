import 'package:hive/hive.dart';
import 'package:flutter/material.dart'; // Added import for TimeOfDay

part 'training.g.dart';

@HiveType(typeId: 3)
class Training {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String teamId;
  @HiveField(2)
  final DateTime date;
  @HiveField(3)
  final TimeOfDay startTime;
  @HiveField(4)
  final TimeOfDay endTime;
  @HiveField(5)
  final String location;
  @HiveField(6)
  final List<String> objectives;
  @HiveField(7)
  final String? coachNotes;

  Training({
    required this.id,
    required this.teamId,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.location,
    required this.objectives,
    this.coachNotes,
  });

  factory Training.create({
    required String teamId,
    required DateTime date,
    required TimeOfDay startTime,
    required TimeOfDay endTime,
    required String location,
    required List<String> objectives,
    String? coachNotes,
  }) {
    return Training(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      teamId: teamId,
      date: date,
      startTime: startTime,
      endTime: endTime,
      location: location,
      objectives: objectives,
      coachNotes: coachNotes,
    );
  }
}

// Custom TypeAdapter for TimeOfDay
class TimeOfDayAdapter extends TypeAdapter<TimeOfDay> {
  @override
  final typeId = 4;

  @override
  TimeOfDay read(BinaryReader reader) {
    final hour = reader.readInt();
    final minute = reader.readInt();
    return TimeOfDay(hour: hour, minute: minute);
  }

  @override
  void write(BinaryWriter writer, TimeOfDay obj) {
    writer.writeInt(obj.hour);
    writer.writeInt(obj.minute);
  }
}
