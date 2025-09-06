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
    );
  }
}
