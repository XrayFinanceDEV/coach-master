enum PlayerMatchStatus {
  convoked,
  playing,
  substitute,
  notPlaying,
}

class MatchConvocation {
  final String id;
  final String matchId;
  final String playerId;
  final PlayerMatchStatus status;

  MatchConvocation({
    required this.id,
    required this.matchId,
    required this.playerId,
    required this.status,
  });

  factory MatchConvocation.create({
    required String matchId,
    required String playerId,
    PlayerMatchStatus status = PlayerMatchStatus.convoked,
  }) {
    return MatchConvocation(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      matchId: matchId,
      playerId: playerId,
      status: status,
    );
  }

  // JSON serialization for Firestore
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'matchId': matchId,
      'playerId': playerId,
      'status': status.name,
    };
  }

  factory MatchConvocation.fromJson(Map<String, dynamic> json) {
    return MatchConvocation(
      id: json['id'] as String,
      matchId: json['matchId'] as String,
      playerId: json['playerId'] as String,
      status: PlayerMatchStatus.values.firstWhere((e) => e.name == json['status']),
    );
  }
}
