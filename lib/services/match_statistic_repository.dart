import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
}

final matchStatisticRepositoryProvider = Provider((ref) => MatchStatisticRepository());
