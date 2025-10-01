import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coachmaster/models/dashboard_data.dart';
import 'package:coachmaster/models/player.dart';
import 'package:coachmaster/models/match.dart';
import 'package:coachmaster/core/firestore_repository_providers.dart';

// Dashboard data provider using Firebase streams
final dashboardDataProvider = Provider.family<AsyncValue<DashboardData?>, String?>((ref, teamId) {
  if (teamId == null || teamId.isEmpty) return const AsyncValue.data(null);

  // Watch the stream providers for players and matches
  final playersAsync = ref.watch(playersForTeamStreamProvider(teamId));
  final matchesAsync = ref.watch(matchesForTeamStreamProvider(teamId));

  // Combine both async values
  return playersAsync.when(
    data: (players) => matchesAsync.when(
      data: (matches) {
        if (kDebugMode) {
          print('🚀 Computing dashboard data for team: $teamId');
        }
        final startTime = DateTime.now();

        final teamStats = _calculateTeamStatisticsOnce(players, matches);
        final leaderboards = _calculateLeaderboardsOnce(players);

        final endTime = DateTime.now();
        if (kDebugMode) {
          print('🚀 Dashboard data computed in ${endTime.difference(startTime).inMilliseconds}ms');
        }

        return AsyncValue.data(DashboardData(
          players: players,
          matches: matches,
          teamStats: teamStats,
          leaderboards: leaderboards,
          calculatedAt: DateTime.now(),
        ));
      },
      loading: () => const AsyncValue.loading(),
      error: (err, stack) => AsyncValue.error(err, stack),
    ),
    loading: () => const AsyncValue.loading(),
    error: (err, stack) => AsyncValue.error(err, stack),
  );
});

TeamStatistics _calculateTeamStatisticsOnce(List<Player> players, List<Match> matches) {
  final completedMatches = matches.where((m) => m.status == MatchStatus.completed).toList();

  int wins = 0;
  int draws = 0;
  int losses = 0;
  int goalsFor = 0;
  int goalsAgainst = 0;

  for (final match in completedMatches) {
    switch (match.result) {
      case MatchResult.win:
        wins++;
        break;
      case MatchResult.draw:
        draws++;
        break;
      case MatchResult.loss:
        losses++;
        break;
      case MatchResult.none:
        break;
    }

    if (match.goalsFor != null && match.goalsAgainst != null) {
      goalsFor += match.goalsFor!;
      goalsAgainst += match.goalsAgainst!;
    }
  }

  final matchesPlayed = completedMatches.length;
  final goalDifference = goalsFor - goalsAgainst;
  final winPercentage = matchesPlayed > 0 ? ((wins / matchesPlayed) * 100).round() : 0;

  return TeamStatistics(
    matchesPlayed: matchesPlayed,
    wins: wins,
    draws: draws,
    losses: losses,
    goalsFor: goalsFor,
    goalsAgainst: goalsAgainst,
    goalDifference: goalDifference,
    winPercentage: winPercentage,
  );
}

PlayerLeaderboards _calculateLeaderboardsOnce(List<Player> players) {
  final playersCopy = List<Player>.from(players);

  final topScorers = List<Player>.from(playersCopy)
    ..sort((a, b) => b.goals.compareTo(a.goals));
  final topScorersLimited = topScorers.take(5).toList();

  final topAssistors = List<Player>.from(playersCopy)
    ..sort((a, b) => b.assists.compareTo(a.assists));
  final topAssistorsLimited = topAssistors.take(5).toList();

  final ratedPlayers = playersCopy.where((p) => p.avgRating != null).toList();
  final topRated = List<Player>.from(ratedPlayers)
    ..sort((a, b) => b.avgRating!.compareTo(a.avgRating!));
  final topRatedLimited = topRated.take(5).toList();

  final sortedByPosition = _sortPlayersByPosition(List<Player>.from(playersCopy));
  final sortedByName = List<Player>.from(playersCopy)
    ..sort((a, b) => a.lastName.compareTo(b.lastName));

  return PlayerLeaderboards(
    topScorers: topScorersLimited,
    topAssistors: topAssistorsLimited,
    topRated: topRatedLimited,
    sortedByPosition: sortedByPosition,
    sortedByName: sortedByName,
  );
}

final _positionOrder = const {
  'Goalkeeper': 1, 'Portiere': 1,
  'Defender': 2, 'Difensore': 2, 'Difensore centrale': 2, 'Terzino': 3,
  'Midfielder': 4, 'Mediano': 4, 'Centrocampista': 5, 'Regista': 6, 'Mezzala': 7,
  'Winger': 8, 'Fascia': 8, 'Esterno': 8,
  'Forward': 9, 'Attaccante': 9, 'Trequartista': 9, 'Seconda punta': 10, 'Punta': 11,
};

List<Player> _sortPlayersByPosition(List<Player> players) {
  return players
    ..sort((a, b) {
      final orderA = _positionOrder[a.position] ?? 99;
      final orderB = _positionOrder[b.position] ?? 99;
      return orderA.compareTo(orderB);
    });
}
