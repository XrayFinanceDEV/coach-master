import 'package:coachmaster/models/player.dart';
import 'package:coachmaster/models/match.dart';

class DashboardData {
  final List<Player> players;
  final List<Match> matches;
  final TeamStatistics teamStats;
  final PlayerLeaderboards leaderboards;
  final DateTime calculatedAt;
  
  const DashboardData({
    required this.players,
    required this.matches,
    required this.teamStats,
    required this.leaderboards,
    required this.calculatedAt,
  });
  
  bool get isStale {
    return DateTime.now().difference(calculatedAt).inMinutes > 5;
  }
}

class TeamStatistics {
  final int matchesPlayed;
  final int wins;
  final int draws;
  final int losses;
  final int goalsFor;
  final int goalsAgainst;
  final int goalDifference;
  final int winPercentage;
  
  const TeamStatistics({
    required this.matchesPlayed,
    required this.wins,
    required this.draws,
    required this.losses,
    required this.goalsFor,
    required this.goalsAgainst,
    required this.goalDifference,
    required this.winPercentage,
  });
  
  Map<String, dynamic> toMap() {
    return {
      'matches': matchesPlayed,
      'wins': wins,
      'draws': draws,
      'losses': losses,
      'goalsFor': goalsFor,
      'goalsAgainst': goalsAgainst,
      'goalDiff': goalDifference,
      'winRate': winPercentage,
    };
  }
}

class PlayerLeaderboards {
  final List<Player> topScorers;
  final List<Player> topAssistors;
  final List<Player> topRated;
  final List<Player> sortedByPosition;
  final List<Player> sortedByName;
  
  const PlayerLeaderboards({
    required this.topScorers,
    required this.topAssistors,
    required this.topRated,
    required this.sortedByPosition,
    required this.sortedByName,
  });
}