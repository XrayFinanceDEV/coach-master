import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:coachmaster/models/match.dart';

class FirestoreMatchRepository {
  final String userId;
  final FirebaseFirestore _firestore;

  late final CollectionReference<Map<String, dynamic>> _collection;

  FirestoreMatchRepository({
    required this.userId,
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance {
    _collection = _firestore.collection('users').doc(userId).collection('matches');

    if (kDebugMode) {
      print('🔥 FirestoreMatchRepository: Initialized for user $userId');
    }
  }

  Future<void> addMatch(Match match) async {
    try {
      await _collection.doc(match.id).set(_toFirestore(match));
      if (kDebugMode) {
        print('🟢 FirestoreMatchRepository: Added match ${match.id}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('🔴 FirestoreMatchRepository: Failed to add match - $e');
      }
      rethrow;
    }
  }

  Future<void> updateMatch(Match match) async {
    try {
      await _collection.doc(match.id).set(_toFirestore(match));
      if (kDebugMode) {
        print('🟢 FirestoreMatchRepository: Updated match ${match.id}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('🔴 FirestoreMatchRepository: Failed to update match - $e');
      }
      rethrow;
    }
  }

  Future<void> deleteMatch(String matchId) async {
    try {
      await _collection.doc(matchId).delete();
      if (kDebugMode) {
        print('🟢 FirestoreMatchRepository: Deleted match $matchId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('🔴 FirestoreMatchRepository: Failed to delete match - $e');
      }
      rethrow;
    }
  }

  Future<Match?> getMatch(String matchId) async {
    try {
      final doc = await _collection.doc(matchId).get();
      if (!doc.exists) return null;
      return _fromFirestore(doc);
    } catch (e) {
      if (kDebugMode) {
        print('🔴 FirestoreMatchRepository: Failed to get match - $e');
      }
      rethrow;
    }
  }

  Future<List<Match>> getMatches() async {
    try {
      final snapshot = await _collection.orderBy('date', descending: true).get();
      return snapshot.docs.map((doc) => _fromFirestore(doc)).toList();
    } catch (e) {
      if (kDebugMode) {
        print('🔴 FirestoreMatchRepository: Failed to get matches - $e');
      }
      rethrow;
    }
  }

  Future<List<Match>> getMatchesForTeam(String teamId) async {
    try {
      final snapshot = await _collection
          .where('teamId', isEqualTo: teamId)
          .orderBy('date', descending: true)
          .get();
      return snapshot.docs.map((doc) => _fromFirestore(doc)).toList();
    } catch (e) {
      if (kDebugMode) {
        print('🔴 FirestoreMatchRepository: Failed to get matches for team - $e');
      }
      rethrow;
    }
  }

  // Real-time Streams
  Stream<List<Match>> matchesStream() {
    return _collection.orderBy('date', descending: true).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => _fromFirestore(doc)).toList();
    });
  }

  Stream<List<Match>> matchesForTeamStream(String teamId) {
    return _collection
        .where('teamId', isEqualTo: teamId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => _fromFirestore(doc)).toList();
    });
  }

  Stream<Match?> matchStream(String matchId) {
    return _collection.doc(matchId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return _fromFirestore(doc);
    });
  }

  // Serialization
  Map<String, dynamic> _toFirestore(Match match) {
    return {
      'id': match.id,
      'teamId': match.teamId,
      'seasonId': match.seasonId,
      'opponent': match.opponent,
      'date': Timestamp.fromDate(match.date),
      'location': match.location,
      'isHome': match.isHome,
      'status': match.status.name,
      'result': match.result.name,
      'goalsFor': match.goalsFor,
      'goalsAgainst': match.goalsAgainst,
      'tactics': match.tactics,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  Match _fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;

    // Handle both old string dates and new Timestamp dates
    DateTime matchDate;
    final dateField = data['date'];
    if (dateField is Timestamp) {
      matchDate = dateField.toDate();
    } else if (dateField is String) {
      matchDate = DateTime.parse(dateField);
    } else {
      throw TypeError();
    }

    return Match(
      id: data['id'] as String,
      teamId: data['teamId'] as String,
      seasonId: data['seasonId'] as String,
      opponent: data['opponent'] as String,
      date: matchDate,
      location: data['location'] as String,
      isHome: data['isHome'] as bool,
      status: MatchStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => MatchStatus.scheduled,
      ),
      result: MatchResult.values.firstWhere(
        (e) => e.name == data['result'],
        orElse: () => MatchResult.none,
      ),
      goalsFor: data['goalsFor'] as int?,
      goalsAgainst: data['goalsAgainst'] as int?,
      tactics: data['tactics'] != null ? Map<String, dynamic>.from(data['tactics']) : null,
    );
  }
}
