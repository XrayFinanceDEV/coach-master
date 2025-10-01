import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Repository for user settings stored in Firestore
/// This ensures settings sync across devices
class FirestoreUserSettingsRepository {
  final String userId;
  final FirebaseFirestore _firestore;

  late final DocumentReference<Map<String, dynamic>> _userDoc;

  FirestoreUserSettingsRepository({
    required this.userId,
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance {
    _userDoc = _firestore.collection('users').doc(userId);

    if (kDebugMode) {
      print('🔥 FirestoreUserSettingsRepository: Initialized for user $userId');
    }
  }

  /// Get user settings
  Future<Map<String, dynamic>?> getSettings() async {
    try {
      final doc = await _userDoc.get();
      if (!doc.exists) {
        if (kDebugMode) {
          print('🟡 FirestoreUserSettingsRepository: No settings found, creating defaults');
        }
        // Create default settings
        await _userDoc.set({
          'selectedTeamId': null,
          'selectedSeasonId': null,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        return null;
      }
      return doc.data();
    } catch (e) {
      if (kDebugMode) {
        print('🔴 FirestoreUserSettingsRepository: Failed to get settings - $e');
      }
      rethrow;
    }
  }

  /// Get selected team ID
  Future<String?> getSelectedTeamId() async {
    try {
      final settings = await getSettings();
      return settings?['selectedTeamId'] as String?;
    } catch (e) {
      if (kDebugMode) {
        print('🔴 FirestoreUserSettingsRepository: Failed to get selected team - $e');
      }
      return null;
    }
  }

  /// Set selected team ID
  Future<void> setSelectedTeamId(String? teamId) async {
    try {
      await _userDoc.set({
        'selectedTeamId': teamId,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (kDebugMode) {
        print('🟢 FirestoreUserSettingsRepository: Saved selected team: $teamId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('🔴 FirestoreUserSettingsRepository: Failed to save selected team - $e');
      }
      rethrow;
    }
  }

  /// Get selected season ID
  Future<String?> getSelectedSeasonId() async {
    try {
      final settings = await getSettings();
      return settings?['selectedSeasonId'] as String?;
    } catch (e) {
      if (kDebugMode) {
        print('🔴 FirestoreUserSettingsRepository: Failed to get selected season - $e');
      }
      return null;
    }
  }

  /// Set selected season ID
  Future<void> setSelectedSeasonId(String? seasonId) async {
    try {
      await _userDoc.set({
        'selectedSeasonId': seasonId,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (kDebugMode) {
        print('🟢 FirestoreUserSettingsRepository: Saved selected season: $seasonId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('🔴 FirestoreUserSettingsRepository: Failed to save selected season - $e');
      }
      rethrow;
    }
  }

  /// Stream of user settings for real-time updates
  Stream<Map<String, dynamic>?> settingsStream() {
    return _userDoc.snapshots().map((doc) {
      if (!doc.exists) return null;
      return doc.data();
    });
  }
}
