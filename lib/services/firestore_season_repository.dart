import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:coachmaster/models/season.dart';

/// Pure Firestore repository for Season entities
/// Firestore provides automatic offline caching and real-time sync
class FirestoreSeasonRepository {
  final String userId;
  final FirebaseFirestore _firestore;

  late final CollectionReference<Map<String, dynamic>> _collection;

  FirestoreSeasonRepository({
    required this.userId,
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance {
    _collection = _firestore.collection('users').doc(userId).collection('seasons');

    if (kDebugMode) {
      print('🔥 FirestoreSeasonRepository: Initialized for user $userId');
    }
  }

  // ============================================================================
  // CRUD Operations
  // ============================================================================

  Future<void> addSeason(Season season) async {
    try {
      await _collection.doc(season.id).set(_toFirestore(season));
      if (kDebugMode) {
        print('🟢 FirestoreSeasonRepository: Added season ${season.id}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('🔴 FirestoreSeasonRepository: Failed to add season - $e');
      }
      rethrow;
    }
  }

  Future<void> updateSeason(Season season) async {
    try {
      await _collection.doc(season.id).set(_toFirestore(season));
      if (kDebugMode) {
        print('🟢 FirestoreSeasonRepository: Updated season ${season.id}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('🔴 FirestoreSeasonRepository: Failed to update season - $e');
      }
      rethrow;
    }
  }

  Future<void> deleteSeason(String seasonId) async {
    try {
      await _collection.doc(seasonId).delete();
      if (kDebugMode) {
        print('🟢 FirestoreSeasonRepository: Deleted season $seasonId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('🔴 FirestoreSeasonRepository: Failed to delete season - $e');
      }
      rethrow;
    }
  }

  Future<Season?> getSeason(String seasonId) async {
    try {
      final doc = await _collection.doc(seasonId).get();
      if (!doc.exists) return null;
      return _fromFirestore(doc);
    } catch (e) {
      if (kDebugMode) {
        print('🔴 FirestoreSeasonRepository: Failed to get season - $e');
      }
      rethrow;
    }
  }

  Future<List<Season>> getSeasons() async {
    try {
      final snapshot = await _collection.orderBy('startDate', descending: true).get();
      return snapshot.docs.map((doc) => _fromFirestore(doc)).toList();
    } catch (e) {
      if (kDebugMode) {
        print('🔴 FirestoreSeasonRepository: Failed to get seasons - $e');
      }
      rethrow;
    }
  }

  // ============================================================================
  // Real-time Streams
  // ============================================================================

  Stream<List<Season>> seasonsStream() {
    return _collection
        .orderBy('startDate', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => _fromFirestore(doc)).toList();
    });
  }

  Stream<Season?> seasonStream(String seasonId) {
    return _collection.doc(seasonId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return _fromFirestore(doc);
    });
  }

  // ============================================================================
  // Serialization
  // ============================================================================

  Map<String, dynamic> _toFirestore(Season season) {
    return {
      'id': season.id,
      'name': season.name,
      'startDate': Timestamp.fromDate(season.startDate),
      'endDate': Timestamp.fromDate(season.endDate),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  Season _fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Season(
      id: data['id'] as String,
      name: data['name'] as String,
      startDate: _parseDate(data['startDate']),
      endDate: _parseDate(data['endDate']),
    );
  }

  DateTime _parseDate(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    } else if (value is String) {
      return DateTime.parse(value);
    }
    throw Exception('Unexpected date format: ${value.runtimeType}');
  }
}
