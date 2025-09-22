import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:coachmaster/models/player.dart';
import 'package:coachmaster/models/match_statistic.dart';
import 'package:coachmaster/models/training_attendance.dart';

class PlayerRepository {
  late Box<Player> _playerBox;

  Future<void> init({String? userId}) async {
    // Use user-specific box to prevent cross-user data conflicts
    final boxName = userId != null ? 'players_$userId' : 'players';
    _playerBox = await Hive.openBox<Player>(boxName);
    
    if (kDebugMode) {
      print('🟦 PlayerRepository: Initialized with box $boxName');
    }
  }

  List<Player> getPlayers() {
    return _playerBox.values.toList();
  }

  Player? getPlayer(String id) {
    return _playerBox.get(id);
  }

  Future<void> addPlayer(Player player) async {
    await _playerBox.put(player.id, player);
  }

  Future<void> updatePlayer(Player player) async {
    await _playerBox.put(player.id, player);
  }

  Future<void> deletePlayer(String id) async {
    await _playerBox.delete(id);
  }

  List<Player> getPlayersForTeam(String teamId) {
    return _playerBox.values.where((player) => player.teamId == teamId).toList();
  }

  // Statistical calculation methods
  Future<void> updatePlayerStatisticsFromMatchStats(String playerId, List<MatchStatistic> allMatchStats) async {
    final player = getPlayer(playerId);
    if (player == null) return;

    final playerMatchStats = allMatchStats.where((stat) => stat.playerId == playerId);
    
    int totalGoals = playerMatchStats.fold(0, (sum, stat) => sum + stat.goals);
    int totalAssists = playerMatchStats.fold(0, (sum, stat) => sum + stat.assists);
    int totalYellowCards = playerMatchStats.fold(0, (sum, stat) => sum + stat.yellowCards);
    int totalRedCards = playerMatchStats.fold(0, (sum, stat) => sum + stat.redCards);
    int totalMinutes = playerMatchStats.fold(0, (sum, stat) => sum + stat.minutesPlayed);
    
    // Calculate average rating (excluding null ratings)
    final ratingsWithValues = playerMatchStats.where((stat) => stat.rating != null);
    double? avgRating;
    if (ratingsWithValues.isNotEmpty) {
      double totalRating = ratingsWithValues.fold(0.0, (sum, stat) => sum + stat.rating!);
      avgRating = totalRating / ratingsWithValues.length;
    }

    final updatedPlayer = player.updateStatistics(
      goals: totalGoals,
      assists: totalAssists,
      yellowCards: totalYellowCards,
      redCards: totalRedCards,
      totalMinutes: totalMinutes,
      avgRating: avgRating,
    );

    await updatePlayer(updatedPlayer);
  }

  Future<void> updatePlayerAbsences(String playerId, List<TrainingAttendance> allAttendances) async {
    final player = getPlayer(playerId);
    if (player == null) {
      if (kDebugMode) {
        print('🔴 PlayerRepository: Player $playerId not found for absence update');
      }
      return;
    }

    final playerAttendances = allAttendances.where((att) => att.playerId == playerId);
    int totalAbsences = playerAttendances.where((att) => att.status == TrainingAttendanceStatus.absent).length;

    if (kDebugMode) {
      print('🟠 PlayerRepository: Updating absences for ${player.firstName} ${player.lastName}');
      print('   Player ID: $playerId');
      print('   Total attendances for player: ${playerAttendances.length}');
      print('   Total absences: $totalAbsences');
      print('   Previous absence count: ${player.absences}');
    }

    final updatedPlayer = player.updateStatistics(absences: totalAbsences);
    await updatePlayer(updatedPlayer);

    if (kDebugMode) {
      print('🟢 PlayerRepository: Updated player absences - new count: ${updatedPlayer.absences}');
    }
  }

  // Get top players for leaderboards
  List<Player> getTopScorers(String teamId, {int limit = 5}) {
    final teamPlayers = getPlayersForTeam(teamId);
    teamPlayers.sort((a, b) => b.goals.compareTo(a.goals));
    return teamPlayers.take(limit).toList();
  }

  List<Player> getTopAssistors(String teamId, {int limit = 5}) {
    final teamPlayers = getPlayersForTeam(teamId);
    teamPlayers.sort((a, b) => b.assists.compareTo(a.assists));
    return teamPlayers.take(limit).toList();
  }

  List<Player> getTopRated(String teamId, {int limit = 5}) {
    final teamPlayers = getPlayersForTeam(teamId);
    final ratedPlayers = teamPlayers.where((p) => p.avgRating != null).toList();
    ratedPlayers.sort((a, b) => b.avgRating!.compareTo(a.avgRating!));
    return ratedPlayers.take(limit).toList();
  }

  List<Player> getMostPresent(String teamId, {int limit = 5}) {
    try {
      debugPrint('getMostPresent called for teamId: $teamId');
      final teamPlayers = getPlayersForTeam(teamId);
      debugPrint('Found ${teamPlayers.length} players for team $teamId');
      
      if (teamPlayers.isEmpty) return [];
      
      // Check each player's absences field to make sure it's accessible
      for (var player in teamPlayers) {
        debugPrint('Player ${player.firstName} ${player.lastName} has ${player.absences} absences');
      }
      
      teamPlayers.sort((a, b) => a.absences.compareTo(b.absences));
      final result = teamPlayers.take(limit).toList();
      debugPrint('getMostPresent returning ${result.length} players');
      return result;
    } catch (e, stackTrace) {
      debugPrint('Error in getMostPresent: $e');
      debugPrint('Stack trace: $stackTrace');
      return [];
    }
  }

  List<Player> getMostAbsences(String teamId, {int limit = 5}) {
    final teamPlayers = getPlayersForTeam(teamId);
    teamPlayers.sort((a, b) => b.absences.compareTo(a.absences));
    return teamPlayers.take(limit).toList();
  }

  // Calculate team totals for dashboard
  Map<String, int> getTeamTotals(String teamId) {
    final teamPlayers = getPlayersForTeam(teamId);
    return {
      'totalGoals': teamPlayers.fold(0, (sum, p) => sum + p.goals),
      'totalAssists': teamPlayers.fold(0, (sum, p) => sum + p.assists),
      'totalYellowCards': teamPlayers.fold(0, (sum, p) => sum + p.yellowCards),
      'totalRedCards': teamPlayers.fold(0, (sum, p) => sum + p.redCards),
      'totalAbsences': teamPlayers.fold(0, (sum, p) => sum + p.absences),
    };
  }

  /// Close the current box (useful for user switching)
  Future<void> close() async {
    try {
      await _playerBox.close();
      if (kDebugMode) {
        print('🟦 PlayerRepository: Closed');
      }
    } catch (e) {
      if (kDebugMode) {
        print('🟦 PlayerRepository: Error closing box: $e');
      }
    }
  }
}
