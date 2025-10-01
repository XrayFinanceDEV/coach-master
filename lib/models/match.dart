enum MatchStatus {
  scheduled,
  live,
  completed,
}

enum MatchResult {
  win,
  loss,
  draw,
  none, // For scheduled or live matches
}

class Match {
  final String id;
  final String teamId;
  final String seasonId;
  final String opponent;
  final DateTime date;
  final String location;
  final bool isHome;
  final int? goalsFor;
  final int? goalsAgainst;
  final MatchResult result;
  final MatchStatus status;
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

  // JSON serialization for Firestore
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'teamId': teamId,
      'seasonId': seasonId,
      'opponent': opponent,
      'date': date.toIso8601String(),
      'location': location,
      'isHome': isHome,
      'goalsFor': goalsFor,
      'goalsAgainst': goalsAgainst,
      'result': result.name,
      'status': status.name,
      'tactics': tactics,
    };
  }

  factory Match.fromJson(Map<String, dynamic> json) {
    return Match(
      id: json['id'] as String,
      teamId: json['teamId'] as String,
      seasonId: json['seasonId'] as String,
      opponent: json['opponent'] as String,
      date: DateTime.parse(json['date'] as String),
      location: json['location'] as String,
      isHome: json['isHome'] as bool,
      goalsFor: (json['goalsFor'] as num?)?.toInt(),
      goalsAgainst: (json['goalsAgainst'] as num?)?.toInt(),
      result: MatchResult.values.firstWhere((e) => e.name == json['result'], orElse: () => MatchResult.none),
      status: MatchStatus.values.firstWhere((e) => e.name == json['status'], orElse: () => MatchStatus.scheduled),
      tactics: json['tactics'] as Map<String, dynamic>?,
    );
  }
}
