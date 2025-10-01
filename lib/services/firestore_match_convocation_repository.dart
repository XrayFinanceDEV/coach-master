import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:coachmaster/models/match_convocation.dart';

class FirestoreMatchConvocationRepository {
  final String userId;
  final FirebaseFirestore _firestore;

  late final CollectionReference<Map<String, dynamic>> _collection;

  FirestoreMatchConvocationRepository({
    required this.userId,
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance {
    _collection = _firestore.collection('users').doc(userId).collection('matchConvocations');

    if (kDebugMode) {
      print('🔥 FirestoreMatchConvocationRepository: Initialized for user $userId');
    }
  }

  Future<void> addConvocation(MatchConvocation convocation) async {
    try {
      await _collection.doc(convocation.id).set(_toFirestore(convocation));
      if (kDebugMode) {
        print('🟢 FirestoreMatchConvocationRepository: Added convocation ${convocation.id}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('🔴 FirestoreMatchConvocationRepository: Failed to add convocation - $e');
      }
      rethrow;
    }
  }

  Future<void> updateConvocation(MatchConvocation convocation) async {
    try {
      await _collection.doc(convocation.id).set(_toFirestore(convocation));
      if (kDebugMode) {
        print('🟢 FirestoreMatchConvocationRepository: Updated convocation ${convocation.id}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('🔴 FirestoreMatchConvocationRepository: Failed to update convocation - $e');
      }
      rethrow;
    }
  }

  Future<void> deleteConvocation(String convocationId) async {
    try {
      await _collection.doc(convocationId).delete();
      if (kDebugMode) {
        print('🟢 FirestoreMatchConvocationRepository: Deleted convocation $convocationId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('🔴 FirestoreMatchConvocationRepository: Failed to delete convocation - $e');
      }
      rethrow;
    }
  }

  Future<MatchConvocation?> getConvocation(String convocationId) async {
    try {
      final doc = await _collection.doc(convocationId).get();
      if (!doc.exists) return null;
      return _fromFirestore(doc);
    } catch (e) {
      if (kDebugMode) {
        print('🔴 FirestoreMatchConvocationRepository: Failed to get convocation - $e');
      }
      rethrow;
    }
  }

  Future<List<MatchConvocation>> getConvocations() async {
    try {
      final snapshot = await _collection.get();
      return snapshot.docs.map((doc) => _fromFirestore(doc)).toList();
    } catch (e) {
      if (kDebugMode) {
        print('🔴 FirestoreMatchConvocationRepository: Failed to get convocations - $e');
      }
      rethrow;
    }
  }

  Future<List<MatchConvocation>> getConvocationsForMatch(String matchId) async {
    try {
      final snapshot = await _collection.where('matchId', isEqualTo: matchId).get();
      return snapshot.docs.map((doc) => _fromFirestore(doc)).toList();
    } catch (e) {
      if (kDebugMode) {
        print('🔴 FirestoreMatchConvocationRepository: Failed to get convocations for match - $e');
      }
      rethrow;
    }
  }

  Future<List<MatchConvocation>> getConvocationsForPlayer(String playerId) async {
    try {
      final snapshot = await _collection.where('playerId', isEqualTo: playerId).get();
      return snapshot.docs.map((doc) => _fromFirestore(doc)).toList();
    } catch (e) {
      if (kDebugMode) {
        print('🔴 FirestoreMatchConvocationRepository: Failed to get convocations for player - $e');
      }
      rethrow;
    }
  }

  Future<void> deleteConvocationsForMatch(String matchId) async {
    try {
      final convocations = await getConvocationsForMatch(matchId);
      for (final convocation in convocations) {
        await deleteConvocation(convocation.id);
      }
      if (kDebugMode) {
        print('🟢 FirestoreMatchConvocationRepository: Deleted all convocations for match $matchId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('🔴 FirestoreMatchConvocationRepository: Failed to delete convocations for match - $e');
      }
      rethrow;
    }
  }

  // Real-time Streams
  Stream<List<MatchConvocation>> convocationsStream() {
    return _collection.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => _fromFirestore(doc)).toList();
    });
  }

  Stream<List<MatchConvocation>> convocationsForMatchStream(String matchId) {
    return _collection.where('matchId', isEqualTo: matchId).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => _fromFirestore(doc)).toList();
    });
  }

  // Serialization
  Map<String, dynamic> _toFirestore(MatchConvocation convocation) {
    return {
      'id': convocation.id,
      'matchId': convocation.matchId,
      'playerId': convocation.playerId,
      'status': convocation.status.name,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  MatchConvocation _fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return MatchConvocation(
      id: data['id'] as String,
      matchId: data['matchId'] as String,
      playerId: data['playerId'] as String,
      status: PlayerMatchStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => PlayerMatchStatus.convoked,
      ),
    );
  }
}
