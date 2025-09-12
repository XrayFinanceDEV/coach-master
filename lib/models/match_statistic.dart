import 'package:hive/hive.dart';

part 'match_statistic.g.dart';

@HiveType(typeId: 8)
class MatchStatistic {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String matchId;
  @HiveField(2)
  final String playerId;
  @HiveField(3)
  final int goals;
  @HiveField(4)
  final int assists;
  @HiveField(5)
  final int yellowCards;
  @HiveField(6)
  final int redCards;
  @HiveField(7)
  final int minutesPlayed;
  @HiveField(8)
  final double? rating;
  @HiveField(9)
  final String? position;
  @HiveField(10)
  final String? notes;

  MatchStatistic({
    required this.id,
    required this.matchId,
    required this.playerId,
    this.goals = 0,
    this.assists = 0,
    this.yellowCards = 0,
    this.redCards = 0,
    this.minutesPlayed = 0,
    this.rating,
    this.position,
    this.notes,
  });

  factory MatchStatistic.create({
    required String matchId,
    required String playerId,
    int goals = 0,
    int assists = 0,
    int yellowCards = 0,
    int redCards = 0,
    int minutesPlayed = 0,
    double? rating,
    String? position,
    String? notes,
  }) {
    return MatchStatistic(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      matchId: matchId,
      playerId: playerId,
      goals: goals,
      assists: assists,
      yellowCards: yellowCards,
      redCards: redCards,
      minutesPlayed: minutesPlayed,
      rating: rating,
      position: position,
      notes: notes,
    );
  }
}
