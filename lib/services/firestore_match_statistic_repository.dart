import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:coachmaster/models/match_statistic.dart';

class FirestoreMatchStatisticRepository {
  final String userId;
  final FirebaseFirestore _firestore;

  late final CollectionReference<Map<String, dynamic>> _collection;

  FirestoreMatchStatisticRepository({
    required this.userId,
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance {
    _collection = _firestore.collection('users').doc(userId).collection('matchStatistics');

    if (kDebugMode) {
      print('🔥 FirestoreMatchStatisticRepository: Initialized for user $userId');
    }
  }

  Future<void> addStatistic(MatchStatistic statistic) async {
    try {
      await _collection.doc(statistic.id).set(_toFirestore(statistic));
      if (kDebugMode) {
        print('🟢 FirestoreMatchStatisticRepository: Added statistic ${statistic.id}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('🔴 FirestoreMatchStatisticRepository: Failed to add statistic - $e');
      }
      rethrow;
    }
  }

  Future<void> updateStatistic(MatchStatistic statistic) async {
    try {
      await _collection.doc(statistic.id).set(_toFirestore(statistic));
      if (kDebugMode) {
        print('🟢 FirestoreMatchStatisticRepository: Updated statistic ${statistic.id}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('🔴 FirestoreMatchStatisticRepository: Failed to update statistic - $e');
      }
      rethrow;
    }
  }

  Future<void> deleteStatistic(String statisticId) async {
    try {
      await _collection.doc(statisticId).delete();
      if (kDebugMode) {
        print('🟢 FirestoreMatchStatisticRepository: Deleted statistic $statisticId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('🔴 FirestoreMatchStatisticRepository: Failed to delete statistic - $e');
      }
      rethrow;
    }
  }

  Future<MatchStatistic?> getStatistic(String statisticId) async {
    try {
      final doc = await _collection.doc(statisticId).get();
      if (!doc.exists) return null;
      return _fromFirestore(doc);
    } catch (e) {
      if (kDebugMode) {
        print('🔴 FirestoreMatchStatisticRepository: Failed to get statistic - $e');
      }
      rethrow;
    }
  }

  Future<List<MatchStatistic>> getStatistics() async {
    try {
      final snapshot = await _collection.get();
      return snapshot.docs.map((doc) => _fromFirestore(doc)).toList();
    } catch (e) {
      if (kDebugMode) {
        print('🔴 FirestoreMatchStatisticRepository: Failed to get statistics - $e');
      }
      rethrow;
    }
  }

  Future<List<MatchStatistic>> getStatisticsForMatch(String matchId) async {
    try {
      final snapshot = await _collection.where('matchId', isEqualTo: matchId).get();
      return snapshot.docs.map((doc) => _fromFirestore(doc)).toList();
    } catch (e) {
      if (kDebugMode) {
        print('🔴 FirestoreMatchStatisticRepository: Failed to get statistics for match - $e');
      }
      rethrow;
    }
  }

  Future<List<MatchStatistic>> getStatisticsForPlayer(String playerId) async {
    try {
      final snapshot = await _collection.where('playerId', isEqualTo: playerId).get();
      return snapshot.docs.map((doc) => _fromFirestore(doc)).toList();
    } catch (e) {
      if (kDebugMode) {
        print('🔴 FirestoreMatchStatisticRepository: Failed to get statistics for player - $e');
      }
      rethrow;
    }
  }

  Future<void> deleteStatisticsForMatch(String matchId) async {
    try {
      final statistics = await getStatisticsForMatch(matchId);
      for (final statistic in statistics) {
        await deleteStatistic(statistic.id);
      }
      if (kDebugMode) {
        print('🟢 FirestoreMatchStatisticRepository: Deleted all statistics for match $matchId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('🔴 FirestoreMatchStatisticRepository: Failed to delete statistics for match - $e');
      }
      rethrow;
    }
  }

  // Real-time Streams
  Stream<List<MatchStatistic>> statisticsStream() {
    return _collection.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => _fromFirestore(doc)).toList();
    });
  }

  Stream<List<MatchStatistic>> statisticsForMatchStream(String matchId) {
    return _collection.where('matchId', isEqualTo: matchId).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => _fromFirestore(doc)).toList();
    });
  }

  Stream<List<MatchStatistic>> statisticsForPlayerStream(String playerId) {
    return _collection.where('playerId', isEqualTo: playerId).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => _fromFirestore(doc)).toList();
    });
  }

  Stream<MatchStatistic?> statisticStream(String statisticId) {
    return _collection.doc(statisticId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return _fromFirestore(doc);
    });
  }

  // Serialization
  Map<String, dynamic> _toFirestore(MatchStatistic statistic) {
    return {
      'id': statistic.id,
      'matchId': statistic.matchId,
      'playerId': statistic.playerId,
      'goals': statistic.goals,
      'assists': statistic.assists,
      'yellowCards': statistic.yellowCards,
      'redCards': statistic.redCards,
      'minutesPlayed': statistic.minutesPlayed,
      'rating': statistic.rating,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  MatchStatistic _fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return MatchStatistic(
      id: data['id'] as String,
      matchId: data['matchId'] as String,
      playerId: data['playerId'] as String,
      goals: data['goals'] as int? ?? 0,
      assists: data['assists'] as int? ?? 0,
      yellowCards: data['yellowCards'] as int? ?? 0,
      redCards: data['redCards'] as int? ?? 0,
      minutesPlayed: data['minutesPlayed'] as int? ?? 0,
      rating: (data['rating'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
