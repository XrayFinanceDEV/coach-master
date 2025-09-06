import 'package:hive/hive.dart';

part 'match_convocation.g.dart';

enum PlayerMatchStatus {
  @HiveField(0)
  convoked,
  @HiveField(1)
  playing,
  @HiveField(2)
  substitute,
  @HiveField(3)
  notPlaying,
}

@HiveType(typeId: 7)
class MatchConvocation {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String matchId;
  @HiveField(2)
  final String playerId;
  @HiveField(3)
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
}
