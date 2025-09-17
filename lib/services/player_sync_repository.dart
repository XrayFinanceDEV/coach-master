import 'package:flutter/foundation.dart';
import 'package:coachmaster/models/player.dart';
import 'package:coachmaster/models/match_statistic.dart';
import 'package:coachmaster/models/training_attendance.dart';
import 'package:coachmaster/services/base_sync_repository.dart';
import 'package:coachmaster/services/firestore_sync_service.dart';

class PlayerSyncRepository extends BaseSyncRepository<Player> {
  PlayerSyncRepository({FirestoreSyncService? syncService}) 
    : super(
        boxName: 'players',
        entityType: 'players',
        syncService: syncService,
      );

  // Legacy methods for backward compatibility
  Future<void> init() async {
    if (!isInitialized) {
      throw Exception('PlayerSyncRepository: Use initForUser() instead of init() for sync support');
    }
  }

  List<Player> getPlayers() => getAll();
  Player? getPlayer(String id) => get(id);

  // Enhanced methods with sync support
  Future<void> addPlayer(Player player) async {
    await addWithSync(player);
  }

  Future<void> updatePlayer(Player player) async {
    await updateWithSync(player);
  }

  Future<void> deletePlayer(String id) async {
    await deleteWithSync(id);
  }

  // Additional query methods
  List<Player> getPlayersForTeam(String teamId) {
    return getAll().where((player) => player.teamId == teamId).toList();
  }

  List<Player> getPlayersByPosition(String position) {
    return getAll().where((player) => player.position.toLowerCase() == position.toLowerCase()).toList();
  }

  List<Player> getAllTopScorers({int limit = 10}) {
    final players = getAll();
    players.sort((a, b) => b.goals.compareTo(a.goals));
    return players.take(limit).toList();
  }

  List<Player> getAllTopAssists({int limit = 10}) {
    final players = getAll();
    players.sort((a, b) => b.assists.compareTo(a.assists));
    return players.take(limit).toList();
  }

  // Team-specific leaderboard methods
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

  List<Player> getMostAbsences(String teamId, {int limit = 5}) {
    final teamPlayers = getPlayersForTeam(teamId);
    teamPlayers.sort((a, b) => b.absences.compareTo(a.absences));
    return teamPlayers.take(limit).toList();
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
    if (player == null) return;

    // Count absences from training attendance records
    final playerAttendances = allAttendances.where((attendance) => attendance.playerId == playerId);
    final absences = playerAttendances.where((attendance) => attendance.status == TrainingAttendanceStatus.absent).length;

    // Create a new player with updated absences using the existing updateStatistics method
    final updatedPlayer = player.updateStatistics(
      goals: player.goals,
      assists: player.assists,
      yellowCards: player.yellowCards,
      redCards: player.redCards,
      totalMinutes: player.totalMinutes,
      avgRating: player.avgRating,
      absences: absences,
    );
    await updatePlayer(updatedPlayer);
  }

  // Implementation of abstract methods from BaseSyncRepository
  @override
  String getEntityId(Player item) => item.id;

  @override
  Map<String, dynamic> toMap(Player item) {
    // Handle photo path - URLs from Firebase Storage are allowed, large base64 data is excluded
    String? safePhotoPath = item.photoPath;
    if (item.photoPath != null && 
        item.photoPath!.length > 1000000 && 
        !item.photoPath!.startsWith('http')) {
      // If the image data is too large and not a URL, exclude it from sync
      // Large base64 images should be uploaded to Firebase Storage first
      if (kDebugMode) {
        print('🖼️ PlayerSync: Excluding large base64 image for ${item.firstName} ${item.lastName} (${item.photoPath!.length} bytes)');
        print('🖼️ PlayerSync: Use Firebase Storage for images > 1MB');
      }
      safePhotoPath = null;
    }
    
    return {
      'id': item.id,
      'teamId': item.teamId,
      'firstName': item.firstName,
      'lastName': item.lastName,
      'position': item.position,
      'preferredFoot': item.preferredFoot,
      'birthDate': item.birthDate.toIso8601String(),
      'photoPath': safePhotoPath,
      'medicalInfo': item.medicalInfo,
      'emergencyContact': item.emergencyContact,
      'goals': item.goals,
      'assists': item.assists,
      'yellowCards': item.yellowCards,
      'redCards': item.redCards,
      'totalMinutes': item.totalMinutes,
      'avgRating': item.avgRating,
      'absences': item.absences,
    };
  }

  @override
  Player fromMap(Map<String, dynamic> map) {
    return Player(
      id: map['id'] as String,
      teamId: map['teamId'] as String,
      firstName: map['firstName'] as String,
      lastName: map['lastName'] as String,
      position: map['position'] as String,
      preferredFoot: map['preferredFoot'] as String,
      birthDate: DateTime.parse(map['birthDate'] as String),
      photoPath: map['photoPath'] as String?,
      medicalInfo: map['medicalInfo'] as Map<String, dynamic>?,
      emergencyContact: map['emergencyContact'] as Map<String, dynamic>?,
      goals: map['goals'] as int? ?? 0,
      assists: map['assists'] as int? ?? 0,
      yellowCards: map['yellowCards'] as int? ?? 0,
      redCards: map['redCards'] as int? ?? 0,
      totalMinutes: map['totalMinutes'] as int? ?? 0,
      avgRating: map['avgRating'] as double?,
      absences: map['absences'] as int? ?? 0,
    );
  }
}