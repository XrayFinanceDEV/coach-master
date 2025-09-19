import 'package:coachmaster/models/match_statistic.dart';

abstract class BaseMatchStatisticRepository {
  // Legacy methods for backward compatibility
  Future<void> init({String? userId});
  
  List<MatchStatistic> getStatistics();
  MatchStatistic? getStatistic(String id);
  
  // Enhanced methods with sync support
  Future<void> addStatistic(MatchStatistic statistic);
  Future<void> updateStatistic(MatchStatistic statistic);
  Future<void> deleteStatistic(String id);
  
  // Additional query methods
  List<MatchStatistic> getStatisticsForMatch(String matchId);
  List<MatchStatistic> getStatisticsForPlayer(String playerId);
  List<MatchStatistic> getStatisticsForMatchAndPlayer(String matchId, String playerId);
  
  // Batch operations for saving multiple player stats for a match
  Future<void> saveMatchStatistics(List<MatchStatistic> statistics);
  Future<void> updateMatchStatistics(String matchId, List<MatchStatistic> newStatistics);
  
  // Delete all statistics for a match (when match is deleted)
  Future<void> deleteStatisticsForMatch(String matchId);
}