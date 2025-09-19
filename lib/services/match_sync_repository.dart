import 'package:coachmaster/models/match.dart';
import 'package:coachmaster/services/base_sync_repository.dart';

class MatchSyncRepository extends BaseSyncRepository<Match> {
  MatchSyncRepository({super.syncService})
    : super(
        boxName: 'matches',
        entityType: 'matches',
      );

  // Legacy methods for backward compatibility
  Future<void> init() async {
    if (!isInitialized) {
      throw Exception('MatchSyncRepository: Use initForUser() instead of init() for sync support');
    }
  }

  List<Match> getMatches() => getAll();
  Match? getMatch(String id) => get(id);

  // Enhanced methods with sync support
  Future<void> addMatch(Match match) async {
    await addWithSync(match);
  }

  Future<void> updateMatch(Match match) async {
    await updateWithSync(match);
  }

  Future<void> deleteMatch(String id) async {
    await deleteWithSync(id);
  }

  // Additional query methods
  List<Match> getMatchesForTeam(String teamId) {
    return getAll().where((match) => match.teamId == teamId).toList();
  }

  List<Match> getMatchesForSeason(String seasonId) {
    return getAll().where((match) => match.seasonId == seasonId).toList();
  }

  List<Match> getMatchesByStatus(MatchStatus status) {
    return getAll().where((match) => match.status == status).toList();
  }

  List<Match> getCompletedMatches() {
    return getAll().where((match) => match.status == MatchStatus.completed).toList();
  }

  List<Match> getUpcomingMatches({int limit = 10}) {
    final now = DateTime.now();
    final upcoming = getAll().where((match) => 
      match.date.isAfter(now) && match.status == MatchStatus.scheduled
    ).toList();
    upcoming.sort((a, b) => a.date.compareTo(b.date));
    return upcoming.take(limit).toList();
  }

  List<Match> getHomeMatches() {
    return getAll().where((match) => match.isHome).toList();
  }

  List<Match> getAwayMatches() {
    return getAll().where((match) => !match.isHome).toList();
  }

  // Team statistics
  Map<String, int> getTeamStats(String teamId) {
    final matches = getMatchesForTeam(teamId).where((m) => m.status == MatchStatus.completed);
    
    int wins = 0, losses = 0, draws = 0;
    int goalsFor = 0, goalsAgainst = 0;
    
    for (final match in matches) {
      switch (match.result) {
        case MatchResult.win:
          wins++;
          break;
        case MatchResult.loss:
          losses++;
          break;
        case MatchResult.draw:
          draws++;
          break;
        case MatchResult.none:
          break;
      }
      
      goalsFor += match.goalsFor ?? 0;
      goalsAgainst += match.goalsAgainst ?? 0;
    }
    
    return {
      'matches': matches.length,
      'wins': wins,
      'losses': losses,
      'draws': draws,
      'goalsFor': goalsFor,
      'goalsAgainst': goalsAgainst,
      'goalDifference': goalsFor - goalsAgainst,
    };
  }

  // Implementation of abstract methods from BaseSyncRepository
  @override
  String getEntityId(Match item) => item.id;

  @override
  Map<String, dynamic> toMap(Match item) {
    return {
      'id': item.id,
      'teamId': item.teamId,
      'seasonId': item.seasonId,
      'opponent': item.opponent,
      'date': item.date.toIso8601String(),
      'location': item.location,
      'isHome': item.isHome,
      'goalsFor': item.goalsFor,
      'goalsAgainst': item.goalsAgainst,
      'result': item.result.name,
      'status': item.status.name,
      'tactics': item.tactics,
    };
  }

  @override
  Match fromMap(Map<String, dynamic> map) {
    return Match(
      id: map['id'] as String,
      teamId: map['teamId'] as String,
      seasonId: map['seasonId'] as String,
      opponent: map['opponent'] as String,
      date: DateTime.parse(map['date'] as String),
      location: map['location'] as String,
      isHome: map['isHome'] as bool,
      goalsFor: map['goalsFor'] as int?,
      goalsAgainst: map['goalsAgainst'] as int?,
      result: MatchResult.values.firstWhere((e) => e.name == (map['result'] as String)),
      status: MatchStatus.values.firstWhere((e) => e.name == (map['status'] as String)),
      tactics: map['tactics'] as Map<String, dynamic>?,
    );
  }
}