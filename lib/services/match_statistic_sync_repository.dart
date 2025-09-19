import 'package:coachmaster/models/match_statistic.dart';
import 'package:coachmaster/services/base_sync_repository.dart';
import 'package:coachmaster/services/base_match_statistic_repository.dart';

class MatchStatisticSyncRepository extends BaseSyncRepository<MatchStatistic> implements BaseMatchStatisticRepository {
  MatchStatisticSyncRepository({super.syncService})
    : super(
        boxName: 'matchStatistics',
        entityType: 'match_statistics',
      );

  // Legacy methods for backward compatibility
  @override
  Future<void> init({String? userId}) async {
    if (!isInitialized) {
      throw Exception('MatchStatisticSyncRepository: Use initForUser() instead of init() for sync support');
    }
  }

  @override
  List<MatchStatistic> getStatistics() => getAll();
  @override
  MatchStatistic? getStatistic(String id) => get(id);

  // Enhanced methods with sync support
  @override
  Future<void> addStatistic(MatchStatistic statistic) async {
    await addWithSync(statistic);
  }

  @override
  Future<void> updateStatistic(MatchStatistic statistic) async {
    await updateWithSync(statistic);
  }

  @override
  Future<void> deleteStatistic(String id) async {
    await deleteWithSync(id);
  }

  // Additional query methods
  @override
  List<MatchStatistic> getStatisticsForMatch(String matchId) {
    return getAll().where((stat) => stat.matchId == matchId).toList();
  }

  @override
  List<MatchStatistic> getStatisticsForPlayer(String playerId) {
    return getAll().where((stat) => stat.playerId == playerId).toList();
  }

  @override
  List<MatchStatistic> getStatisticsForMatchAndPlayer(String matchId, String playerId) {
    return getAll()
        .where((stat) => stat.matchId == matchId && stat.playerId == playerId)
        .toList();
  }

  // Batch operations for saving multiple player stats for a match
  @override
  Future<void> saveMatchStatistics(List<MatchStatistic> statistics) async {
    for (final stat in statistics) {
      await addWithSync(stat);
    }
  }

  @override
  Future<void> updateMatchStatistics(String matchId, List<MatchStatistic> newStatistics) async {
    // Delete existing statistics for this match
    final existingStats = getStatisticsForMatch(matchId);
    for (final stat in existingStats) {
      await deleteWithSync(stat.id);
    }
    
    // Add new statistics
    await saveMatchStatistics(newStatistics);
  }

  // Delete all statistics for a match (when match is deleted)
  @override
  Future<void> deleteStatisticsForMatch(String matchId) async {
    final matchStats = getStatisticsForMatch(matchId);
    for (final stat in matchStats) {
      await deleteWithSync(stat.id);
    }
  }

  // Implementation of abstract methods from BaseSyncRepository
  @override
  String getEntityId(MatchStatistic item) => item.id;

  @override
  Map<String, dynamic> toMap(MatchStatistic item) {
    return {
      'id': item.id,
      'matchId': item.matchId,
      'playerId': item.playerId,
      'goals': item.goals,
      'assists': item.assists,
      'yellowCards': item.yellowCards,
      'redCards': item.redCards,
      'minutesPlayed': item.minutesPlayed,
      'rating': item.rating,
      'position': item.position,
      'notes': item.notes,
      'createdAt': DateTime.now().toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    };
  }

  @override
  MatchStatistic fromMap(Map<String, dynamic> map) {
    return MatchStatistic(
      id: map['id'] as String,
      matchId: map['matchId'] as String,
      playerId: map['playerId'] as String,
      goals: map['goals'] as int? ?? 0,
      assists: map['assists'] as int? ?? 0,
      yellowCards: map['yellowCards'] as int? ?? 0,
      redCards: map['redCards'] as int? ?? 0,
      minutesPlayed: map['minutesPlayed'] as int? ?? 0,
      rating: map['rating'] as double?,
      position: map['position'] as String?,
      notes: map['notes'] as String?,
    );
  }
}