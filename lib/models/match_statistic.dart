class MatchStatistic {
  final String id;
  final String matchId;
  final String playerId;
  final int goals;
  final int assists;
  final int yellowCards;
  final int redCards;
  final int minutesPlayed;
  final double? rating;
  final String? position;
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

  // JSON serialization for Firestore
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'matchId': matchId,
      'playerId': playerId,
      'goals': goals,
      'assists': assists,
      'yellowCards': yellowCards,
      'redCards': redCards,
      'minutesPlayed': minutesPlayed,
      'rating': rating,
      'position': position,
      'notes': notes,
    };
  }

  factory MatchStatistic.fromJson(Map<String, dynamic> json) {
    return MatchStatistic(
      id: json['id'] as String,
      matchId: json['matchId'] as String,
      playerId: json['playerId'] as String,
      goals: (json['goals'] as num?)?.toInt() ?? 0,
      assists: (json['assists'] as num?)?.toInt() ?? 0,
      yellowCards: (json['yellowCards'] as num?)?.toInt() ?? 0,
      redCards: (json['redCards'] as num?)?.toInt() ?? 0,
      minutesPlayed: (json['minutesPlayed'] as num?)?.toInt() ?? 0,
      rating: (json['rating'] as num?)?.toDouble(),
      position: json['position'] as String?,
      notes: json['notes'] as String?,
    );
  }
}
