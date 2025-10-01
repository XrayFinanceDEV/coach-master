import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:coachmaster/models/team.dart';

class FirestoreTeamRepository {
  final String userId;
  final FirebaseFirestore _firestore;

  late final CollectionReference<Map<String, dynamic>> _collection;

  FirestoreTeamRepository({
    required this.userId,
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance {
    _collection = _firestore.collection('users').doc(userId).collection('teams');

    if (kDebugMode) {
      print('🔥 FirestoreTeamRepository: Initialized for user $userId');
    }
  }

  Future<void> addTeam(Team team) async {
    try {
      await _collection.doc(team.id).set(_toFirestore(team));
      if (kDebugMode) {
        print('🟢 FirestoreTeamRepository: Added team ${team.id}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('🔴 FirestoreTeamRepository: Failed to add team - $e');
      }
      rethrow;
    }
  }

  Future<void> updateTeam(Team team) async {
    try {
      await _collection.doc(team.id).set(_toFirestore(team));
      if (kDebugMode) {
        print('🟢 FirestoreTeamRepository: Updated team ${team.id}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('🔴 FirestoreTeamRepository: Failed to update team - $e');
      }
      rethrow;
    }
  }

  Future<void> deleteTeam(String teamId) async {
    try {
      await _collection.doc(teamId).delete();
      if (kDebugMode) {
        print('🟢 FirestoreTeamRepository: Deleted team $teamId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('🔴 FirestoreTeamRepository: Failed to delete team - $e');
      }
      rethrow;
    }
  }

  Future<Team?> getTeam(String teamId) async {
    try {
      final doc = await _collection.doc(teamId).get();
      if (!doc.exists) return null;
      return _fromFirestore(doc);
    } catch (e) {
      if (kDebugMode) {
        print('🔴 FirestoreTeamRepository: Failed to get team - $e');
      }
      rethrow;
    }
  }

  Future<List<Team>> getTeams() async {
    try {
      final snapshot = await _collection.get();
      return snapshot.docs.map((doc) => _fromFirestore(doc)).toList();
    } catch (e) {
      if (kDebugMode) {
        print('🔴 FirestoreTeamRepository: Failed to get teams - $e');
      }
      rethrow;
    }
  }

  Future<List<Team>> getTeamsForSeason(String seasonId) async {
    try {
      final snapshot = await _collection.where('seasonId', isEqualTo: seasonId).get();
      return snapshot.docs.map((doc) => _fromFirestore(doc)).toList();
    } catch (e) {
      if (kDebugMode) {
        print('🔴 FirestoreTeamRepository: Failed to get teams for season - $e');
      }
      rethrow;
    }
  }

  // Real-time Streams
  Stream<List<Team>> teamsStream() {
    return _collection.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => _fromFirestore(doc)).toList();
    });
  }

  Stream<List<Team>> teamsForSeasonStream(String seasonId) {
    return _collection.where('seasonId', isEqualTo: seasonId).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => _fromFirestore(doc)).toList();
    });
  }

  Stream<Team?> teamStream(String teamId) {
    return _collection.doc(teamId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return _fromFirestore(doc);
    });
  }

  // Serialization
  Map<String, dynamic> _toFirestore(Team team) {
    return {
      'id': team.id,
      'seasonId': team.seasonId,
      'name': team.name,
      'description': team.description,
      'logoPath': team.logoPath,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  Team _fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Team(
      id: data['id'] as String,
      seasonId: data['seasonId'] as String,
      name: data['name'] as String,
      description: data['description'] as String?,
      logoPath: data['logoPath'] as String?,
    );
  }
}
