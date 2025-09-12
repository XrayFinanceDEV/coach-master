import 'package:hive_flutter/hive_flutter.dart';
import 'package:coachmaster/models/match_statistic.dart';

class MatchStatisticRepository {
  late Box<MatchStatistic> _statisticBox;

  Future<void> init() async {
    _statisticBox = await Hive.openBox<MatchStatistic>('matchStatistics');
  }

  List<MatchStatistic> getStatistics() {
    return _statisticBox.values.toList();
  }

  MatchStatistic? getStatistic(String id) {
    return _statisticBox.get(id);
  }

  Future<void> addStatistic(MatchStatistic statistic) async {
    await _statisticBox.put(statistic.id, statistic);
  }

  Future<void> updateStatistic(MatchStatistic statistic) async {
    await _statisticBox.put(statistic.id, statistic);
  }

  Future<void> deleteStatistic(String id) async {
    await _statisticBox.delete(id);
  }

  List<MatchStatistic> getStatisticsForMatch(String matchId) {
    return _statisticBox.values.where((stat) => stat.matchId == matchId).toList();
  }

  List<MatchStatistic> getStatisticsForPlayer(String playerId) {
    return _statisticBox.values.where((stat) => stat.playerId == playerId).toList();
  }

  List<MatchStatistic> getStatisticsForMatchAndPlayer(String matchId, String playerId) {
    return _statisticBox.values
        .where((stat) => stat.matchId == matchId && stat.playerId == playerId)
        .toList();
  }

  // Batch operations for saving multiple player stats for a match
  Future<void> saveMatchStatistics(List<MatchStatistic> statistics) async {
    for (final stat in statistics) {
      await _statisticBox.put(stat.id, stat);
    }
  }

  Future<void> updateMatchStatistics(String matchId, List<MatchStatistic> newStatistics) async {
    // Delete existing statistics for this match
    final existingStats = getStatisticsForMatch(matchId);
    for (final stat in existingStats) {
      await _statisticBox.delete(stat.id);
    }
    
    // Add new statistics
    await saveMatchStatistics(newStatistics);
  }

  // Delete all statistics for a match (when match is deleted)
  Future<void> deleteStatisticsForMatch(String matchId) async {
    final matchStats = getStatisticsForMatch(matchId);
    for (final stat in matchStats) {
      await _statisticBox.delete(stat.id);
    }
  }
}
