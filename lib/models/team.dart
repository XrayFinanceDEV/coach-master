import 'package:hive/hive.dart';

part 'team.g.dart';

@HiveType(typeId: 1)
class Team {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String seasonId;
  @HiveField(2)
  final String name;
  @HiveField(3)
  final String? description;
  @HiveField(4)
  final String? logoPath; // Local path to the logo file

  Team({
    required this.id,
    required this.seasonId,
    required this.name,
    this.description,
    this.logoPath,
  });

  factory Team.create({
    required String name,
    required String seasonId,
    String? description,
    String? logoPath,
  }) {
    return Team(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      seasonId: seasonId,
      name: name,
      description: description,
      logoPath: logoPath,
    );
  }
}
