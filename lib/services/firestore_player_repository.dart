import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:coachmaster/models/player.dart';
import 'package:coachmaster/models/training_attendance.dart';
import 'package:coachmaster/models/match_statistic.dart';

/// Pure Firestore repository for Player entities
/// No local Hive storage - Firestore is the single source of truth
/// Firestore provides automatic offline caching and real-time sync
class FirestorePlayerRepository {
  final String userId;
  final FirebaseFirestore _firestore;

  // Firestore collection reference for this user's players
  late final CollectionReference<Map<String, dynamic>> _collection;

  FirestorePlayerRepository({
    required this.userId,
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance {
    _collection = _firestore.collection('users').doc(userId).collection('players');

    if (kDebugMode) {
      print('🔥 FirestorePlayerRepository: Initialized for user $userId');
    }
  }

  // ============================================================================
  // CRUD Operations - Direct Firestore access
  // ============================================================================

  /// Add a new player
  Future<void> addPlayer(Player player) async {
    try {
      // Write to cache immediately, sync to server in background
      await _collection.doc(player.id).set(
        _toFirestore(player),
        SetOptions(merge: true),
      );

      if (kDebugMode) {
        print('🟢 FirestorePlayerRepository: Added player ${player.id}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('🔴 FirestorePlayerRepository: Failed to add player - $e');
      }
      rethrow;
    }
  }

  /// Update an existing player
  Future<void> updatePlayer(Player player) async {
    try {
      // Use set without merge to ensure null values overwrite existing data
      await _collection.doc(player.id).set(
        _toFirestore(player),
      );

      if (kDebugMode) {
        print('🟢 FirestorePlayerRepository: Updated player ${player.id}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('🔴 FirestorePlayerRepository: Failed to update player - $e');
      }
      rethrow;
    }
  }

  /// Delete a player
  Future<void> deletePlayer(String playerId) async {
    try {
      await _collection.doc(playerId).delete();

      if (kDebugMode) {
        print('🟢 FirestorePlayerRepository: Deleted player $playerId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('🔴 FirestorePlayerRepository: Failed to delete player - $e');
      }
      rethrow;
    }
  }

  /// Get a single player by ID
  Future<Player?> getPlayer(String playerId) async {
    try {
      final doc = await _collection.doc(playerId).get();

      if (!doc.exists) {
        return null;
      }

      return _fromFirestore(doc);
    } catch (e) {
      if (kDebugMode) {
        print('🔴 FirestorePlayerRepository: Failed to get player - $e');
      }
      rethrow;
    }
  }

  /// Get all players for this user
  Future<List<Player>> getPlayers() async {
    try {
      final snapshot = await _collection.get();
      return snapshot.docs.map((doc) => _fromFirestore(doc)).toList();
    } catch (e) {
      if (kDebugMode) {
        print('🔴 FirestorePlayerRepository: Failed to get players - $e');
      }
      rethrow;
    }
  }

  /// Get all players for a specific team
  Future<List<Player>> getPlayersForTeam(String teamId) async {
    try {
      final snapshot = await _collection.where('teamId', isEqualTo: teamId).get();
      return snapshot.docs.map((doc) => _fromFirestore(doc)).toList();
    } catch (e) {
      if (kDebugMode) {
        print('🔴 FirestorePlayerRepository: Failed to get players for team - $e');
      }
      rethrow;
    }
  }

  // ============================================================================
  // Real-time Streams - Auto-updating data
  // ============================================================================

  /// Stream all players (real-time updates)
  Stream<List<Player>> playersStream() {
    return _collection.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => _fromFirestore(doc)).toList();
    });
  }

  /// Stream players for a specific team (real-time updates)
  Stream<List<Player>> playersForTeamStream(String teamId) {
    return _collection
        .where('teamId', isEqualTo: teamId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => _fromFirestore(doc)).toList();
    });
  }

  /// Stream a single player (real-time updates)
  Stream<Player?> playerStream(String playerId) {
    return _collection.doc(playerId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return _fromFirestore(doc);
    });
  }

  // ============================================================================
  // Statistics Updates
  // ============================================================================

  /// Update player statistics from match statistics
  Future<void> updatePlayerStatisticsFromMatchStats(
    String playerId,
    List<MatchStatistic> allMatchStats,
  ) async {
    final player = await getPlayer(playerId);
    if (player == null) {
      if (kDebugMode) {
        print('🔴 FirestorePlayerRepository: Player $playerId not found for stats update');
      }
      return;
    }

    // Calculate aggregate statistics
    final playerStats = allMatchStats.where((stat) => stat.playerId == playerId);

    final totalGoals = playerStats.fold<int>(0, (total, stat) => total + stat.goals);
    final totalAssists = playerStats.fold<int>(0, (total, stat) => total + stat.assists);
    final totalYellowCards = playerStats.fold<int>(0, (total, stat) => total + stat.yellowCards);
    final totalRedCards = playerStats.fold<int>(0, (total, stat) => total + stat.redCards);
    final totalMinutes = playerStats.fold<int>(0, (total, stat) => total + stat.minutesPlayed);
    final ratingsCount = playerStats.where((stat) => stat.rating != null && stat.rating! > 0).length;
    final avgRating = ratingsCount > 0
        ? playerStats.fold<double>(0, (total, stat) => total + (stat.rating ?? 0.0)) / ratingsCount
        : null;

    if (kDebugMode) {
      print('🟠 FirestorePlayerRepository: Updating stats for ${player.firstName} ${player.lastName}');
      print('   Goals: $totalGoals, Assists: $totalAssists, Avg Rating: ${avgRating?.toStringAsFixed(1) ?? "N/A"}');
      print('   Yellow Cards: $totalYellowCards, Red Cards: $totalRedCards, Minutes: $totalMinutes');
    }

    // Update player with new statistics
    final updatedPlayer = player.updateStatistics(
      goals: totalGoals,
      assists: totalAssists,
      yellowCards: totalYellowCards,
      redCards: totalRedCards,
      totalMinutes: totalMinutes,
      avgRating: avgRating,
      absences: player.absences,
    );

    await updatePlayer(updatedPlayer);

    if (kDebugMode) {
      print('🟢 FirestorePlayerRepository: Updated player statistics');
    }
  }

  /// Update player absences from training attendance
  Future<void> updatePlayerAbsences(
    String playerId,
    List<TrainingAttendance> allAttendances,
  ) async {
    final player = await getPlayer(playerId);
    if (player == null) {
      if (kDebugMode) {
        print('🔴 FirestorePlayerRepository: Player $playerId not found for absence update');
      }
      return;
    }

    // Count absences
    final playerAttendances = allAttendances.where((a) => a.playerId == playerId);
    final absences = playerAttendances
        .where((a) => a.status == TrainingAttendanceStatus.absent)
        .length;

    if (kDebugMode) {
      print('🟠 FirestorePlayerRepository: Updating absences for ${player.firstName} ${player.lastName}');
      print('   Total absences: $absences (previous: ${player.absences})');
    }

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

    if (kDebugMode) {
      print('🟢 FirestorePlayerRepository: Updated player absences');
    }
  }

  // ============================================================================
  // Serialization - Firestore format
  // ============================================================================

  /// Convert Player to Firestore map
  Map<String, dynamic> _toFirestore(Player player) {
    // Handle photo path - URLs from Firebase Storage are allowed, large base64 excluded
    String? safePhotoPath = player.photoPath;
    if (player.photoPath != null &&
        player.photoPath!.startsWith('data:') &&
        player.photoPath!.length > 1000) {
      safePhotoPath = null; // Exclude large base64 data
    }

    return {
      'id': player.id,
      'teamId': player.teamId,
      'firstName': player.firstName,
      'lastName': player.lastName,
      'birthDate': Timestamp.fromDate(player.birthDate),
      'position': player.position,
      'photoPath': safePhotoPath,
      'preferredFoot': player.preferredFoot,
      'medicalInfo': player.medicalInfo,
      'emergencyContact': player.emergencyContact,
      'goals': player.goals,
      'assists': player.assists,
      'yellowCards': player.yellowCards,
      'redCards': player.redCards,
      'totalMinutes': player.totalMinutes,
      'avgRating': player.avgRating,
      'absences': player.absences,
      // Metadata
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  // ============================================================================
  // Leaderboard Query Methods
  // ============================================================================

  /// Get top scorers (players with most goals)
  Future<List<Player>> getTopScorers({int limit = 5}) async {
    try {
      final players = await getPlayers();
      final sorted = players..sort((a, b) => b.goals.compareTo(a.goals));
      return sorted.take(limit).toList();
    } catch (e) {
      if (kDebugMode) {
        print('🔴 FirestorePlayerRepository: Failed to get top scorers - $e');
      }
      rethrow;
    }
  }

  /// Get top assistors (players with most assists)
  Future<List<Player>> getTopAssistors({int limit = 5}) async {
    try {
      final players = await getPlayers();
      final sorted = players..sort((a, b) => b.assists.compareTo(a.assists));
      return sorted.take(limit).toList();
    } catch (e) {
      if (kDebugMode) {
        print('🔴 FirestorePlayerRepository: Failed to get top assistors - $e');
      }
      rethrow;
    }
  }

  /// Get top rated players (players with highest average rating)
  Future<List<Player>> getTopRated({int limit = 5}) async {
    try {
      final players = await getPlayers();
      final ratedPlayers = players.where((p) => p.avgRating != null).toList();
      final sorted = ratedPlayers..sort((a, b) => b.avgRating!.compareTo(a.avgRating!));
      return sorted.take(limit).toList();
    } catch (e) {
      if (kDebugMode) {
        print('🔴 FirestorePlayerRepository: Failed to get top rated - $e');
      }
      rethrow;
    }
  }

  /// Get players with most absences
  Future<List<Player>> getMostAbsences({int limit = 5}) async {
    try {
      final players = await getPlayers();
      final sorted = players..sort((a, b) => b.absences.compareTo(a.absences));
      return sorted.take(limit).toList();
    } catch (e) {
      if (kDebugMode) {
        print('🔴 FirestorePlayerRepository: Failed to get most absences - $e');
      }
      rethrow;
    }
  }

  // ============================================================================
  // Serialization
  // ============================================================================

  /// Convert Firestore document to Player
  Player _fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;

    // Parse birthDate - handle both Timestamp and String formats for backward compatibility
    DateTime birthDate;
    final birthDateData = data['birthDate'];
    if (birthDateData is Timestamp) {
      birthDate = birthDateData.toDate();
    } else if (birthDateData is String) {
      // Legacy format - parse ISO 8601 string
      birthDate = DateTime.parse(birthDateData);
    } else if (birthDateData is int) {
      // Legacy format - milliseconds since epoch
      birthDate = DateTime.fromMillisecondsSinceEpoch(birthDateData);
    } else {
      // Fallback to a default date if format is unexpected
      if (kDebugMode) {
        print('⚠️ FirestorePlayerRepository: Unexpected birthDate format for player ${data['id']}: $birthDateData');
      }
      birthDate = DateTime(2000, 1, 1); // Default fallback date
    }

    return Player(
      id: data['id'] as String,
      teamId: data['teamId'] as String,
      firstName: data['firstName'] as String,
      lastName: data['lastName'] as String,
      birthDate: birthDate,
      position: data['position'] as String? ?? 'Unknown',
      photoPath: data['photoPath'] as String?,
      preferredFoot: data['preferredFoot'] as String? ?? 'Both',
      medicalInfo: data['medicalInfo'] != null ? Map<String, dynamic>.from(data['medicalInfo']) : null,
      emergencyContact: data['emergencyContact'] != null ? Map<String, dynamic>.from(data['emergencyContact']) : null,
      goals: data['goals'] as int? ?? 0,
      assists: data['assists'] as int? ?? 0,
      yellowCards: data['yellowCards'] as int? ?? 0,
      redCards: data['redCards'] as int? ?? 0,
      totalMinutes: data['totalMinutes'] as int? ?? 0,
      avgRating: (data['avgRating'] as num?)?.toDouble(),
      absences: data['absences'] as int? ?? 0,
    );
  }
}
