import 'package:flutter/material.dart';

class Training {
  final String id;
  final String teamId;
  final DateTime date;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final String location;
  final List<String> objectives;
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

  // JSON serialization for Firestore
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'teamId': teamId,
      'date': date.toIso8601String(),
      'startTime': '${startTime.hour}:${startTime.minute}',
      'endTime': '${endTime.hour}:${endTime.minute}',
      'location': location,
      'objectives': objectives,
      'coachNotes': coachNotes,
    };
  }

  factory Training.fromJson(Map<String, dynamic> json) {
    final startTimeParts = (json['startTime'] as String).split(':');
    final endTimeParts = (json['endTime'] as String).split(':');

    return Training(
      id: json['id'] as String,
      teamId: json['teamId'] as String,
      date: DateTime.parse(json['date'] as String),
      startTime: TimeOfDay(
        hour: int.parse(startTimeParts[0]),
        minute: int.parse(startTimeParts[1]),
      ),
      endTime: TimeOfDay(
        hour: int.parse(endTimeParts[0]),
        minute: int.parse(endTimeParts[1]),
      ),
      location: json['location'] as String,
      objectives: List<String>.from(json['objectives'] as List),
      coachNotes: json['coachNotes'] as String?,
    );
  }
}
