import 'package:hive/hive.dart';

part 'player.g.dart';

@HiveType(typeId: 2)
class Player {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String teamId;
  @HiveField(2)
  final String firstName;
  @HiveField(3)
  final String lastName;
  @HiveField(4)
  final String position;
  @HiveField(5)
  final String preferredFoot;
  @HiveField(6)
  final DateTime birthDate;
  @HiveField(7)
  final String? photoPath; // Local path to player photo
  @HiveField(8)
  final Map<String, dynamic>? medicalInfo;
  @HiveField(9)
  final Map<String, dynamic>? emergencyContact;
  // Statistical fields
  @HiveField(10)
  final int goals;
  @HiveField(11)
  final int assists;
  @HiveField(12)
  final int yellowCards;
  @HiveField(13)
  final int redCards;
  @HiveField(14)
  final int totalMinutes;
  @HiveField(15)
  final double? avgRating;
  @HiveField(16)
  final int absences;

  Player({
    required this.id,
    required this.teamId,
    required this.firstName,
    required this.lastName,
    required this.position,
    required this.preferredFoot,
    required this.birthDate,
    this.photoPath,
    this.medicalInfo,
    this.emergencyContact,
    this.goals = 0,
    this.assists = 0,
    this.yellowCards = 0,
    this.redCards = 0,
    this.totalMinutes = 0,
    this.avgRating,
    this.absences = 0,
  });

  factory Player.create({
    required String teamId,
    required String firstName,
    required String lastName,
    String position = 'Unknown',
    String preferredFoot = 'Both',
    required DateTime birthDate,
    String? photoPath,
    Map<String, dynamic>? medicalInfo,
    Map<String, dynamic>? emergencyContact,
    int goals = 0,
    int assists = 0,
    int yellowCards = 0,
    int redCards = 0,
    int totalMinutes = 0,
    double? avgRating,
    int absences = 0,
  }) {
    return Player(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      teamId: teamId,
      firstName: firstName,
      lastName: lastName,
      position: position,
      preferredFoot: preferredFoot,
      birthDate: birthDate,
      photoPath: photoPath,
      medicalInfo: medicalInfo,
      emergencyContact: emergencyContact,
      goals: goals,
      assists: assists,
      yellowCards: yellowCards,
      redCards: redCards,
      totalMinutes: totalMinutes,
      avgRating: avgRating,
      absences: absences,
    );
  }

  // Convenience method to update statistics
  Player updateStatistics({
    int? goals,
    int? assists,
    int? yellowCards,
    int? redCards,
    int? totalMinutes,
    double? avgRating,
    int? absences,
  }) {
    return Player(
      id: id,
      teamId: teamId,
      firstName: firstName,
      lastName: lastName,
      position: position,
      preferredFoot: preferredFoot,
      birthDate: birthDate,
      photoPath: photoPath,
      medicalInfo: medicalInfo,
      emergencyContact: emergencyContact,
      goals: goals ?? this.goals,
      assists: assists ?? this.assists,
      yellowCards: yellowCards ?? this.yellowCards,
      redCards: redCards ?? this.redCards,
      totalMinutes: totalMinutes ?? this.totalMinutes,
      avgRating: avgRating ?? this.avgRating,
      absences: absences ?? this.absences,
    );
  }
}
