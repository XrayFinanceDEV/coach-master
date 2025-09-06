import 'package:hive/hive.dart';

part 'match.g.dart';

enum MatchStatus {
  @HiveField(0)
  scheduled,
  @HiveField(1)
  live,
  @HiveField(2)
  completed,
}

enum MatchResult {
  @HiveField(0)
  win,
  @HiveField(1)
  loss,
  @HiveField(2)
  draw,
  @HiveField(3)
  none, // For scheduled or live matches
}

@HiveType(typeId: 6)
class Match {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String teamId;
  @HiveField(2)
  final String seasonId;
  @HiveField(3)
  final String opponent;
  @HiveField(4)
  final DateTime date;
  @HiveField(5)
  final String location;
  @HiveField(6)
  final bool isHome;
  @HiveField(7)
  final int? goalsFor;
  @HiveField(8)
  final int? goalsAgainst;
  @HiveField(9)
  final MatchResult result;
  @HiveField(10)
  final MatchStatus status;
  @HiveField(11)
  final Map<String, dynamic>? tactics; // Storing as dynamic map for now

  Match({
    required this.id,
    required this.teamId,
    required this.seasonId,
    required this.opponent,
    required this.date,
    required this.location,
    required this.isHome,
    this.goalsFor,
    this.goalsAgainst,
    this.result = MatchResult.none,
    this.status = MatchStatus.scheduled,
    this.tactics,
  });

  factory Match.create({
    required String teamId,
    required String seasonId,
    required String opponent,
    required DateTime date,
    required String location,
    required bool isHome,
    int? goalsFor,
    int? goalsAgainst,
    MatchResult result = MatchResult.none,
    MatchStatus status = MatchStatus.scheduled,
    Map<String, dynamic>? tactics,
  }) {
    return Match(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      teamId: teamId,
      seasonId: seasonId,
      opponent: opponent,
      date: date,
      location: location,
      isHome: isHome,
      goalsFor: goalsFor,
      goalsAgainst: goalsAgainst,
      result: result,
      status: status,
      tactics: tactics,
    );
  }
}
