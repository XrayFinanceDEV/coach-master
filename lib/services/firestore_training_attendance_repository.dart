import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:coachmaster/models/training_attendance.dart';

class FirestoreTrainingAttendanceRepository {
  final String userId;
  final FirebaseFirestore _firestore;

  late final CollectionReference<Map<String, dynamic>> _collection;

  FirestoreTrainingAttendanceRepository({
    required this.userId,
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance {
    _collection = _firestore.collection('users').doc(userId).collection('trainingAttendances');

    if (kDebugMode) {
      print('🔥 FirestoreTrainingAttendanceRepository: Initialized for user $userId');
    }
  }

  Future<void> addAttendance(TrainingAttendance attendance) async {
    try {
      await _collection.doc(attendance.id).set(_toFirestore(attendance));
      if (kDebugMode) {
        print('🟢 FirestoreTrainingAttendanceRepository: Added attendance ${attendance.id}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('🔴 FirestoreTrainingAttendanceRepository: Failed to add attendance - $e');
      }
      rethrow;
    }
  }

  Future<void> updateAttendance(TrainingAttendance attendance) async {
    try {
      await _collection.doc(attendance.id).set(_toFirestore(attendance));
      if (kDebugMode) {
        print('🟢 FirestoreTrainingAttendanceRepository: Updated attendance ${attendance.id}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('🔴 FirestoreTrainingAttendanceRepository: Failed to update attendance - $e');
      }
      rethrow;
    }
  }

  Future<void> deleteAttendance(String attendanceId) async {
    try {
      await _collection.doc(attendanceId).delete();
      if (kDebugMode) {
        print('🟢 FirestoreTrainingAttendanceRepository: Deleted attendance $attendanceId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('🔴 FirestoreTrainingAttendanceRepository: Failed to delete attendance - $e');
      }
      rethrow;
    }
  }

  Future<TrainingAttendance?> getAttendance(String attendanceId) async {
    try {
      final doc = await _collection.doc(attendanceId).get();
      if (!doc.exists) return null;
      return _fromFirestore(doc);
    } catch (e) {
      if (kDebugMode) {
        print('🔴 FirestoreTrainingAttendanceRepository: Failed to get attendance - $e');
      }
      rethrow;
    }
  }

  Future<List<TrainingAttendance>> getAttendances() async {
    try {
      final snapshot = await _collection.get();
      return snapshot.docs.map((doc) => _fromFirestore(doc)).toList();
    } catch (e) {
      if (kDebugMode) {
        print('🔴 FirestoreTrainingAttendanceRepository: Failed to get attendances - $e');
      }
      rethrow;
    }
  }

  Future<List<TrainingAttendance>> getAttendancesForTraining(String trainingId) async {
    try {
      final snapshot = await _collection.where('trainingId', isEqualTo: trainingId).get();
      return snapshot.docs.map((doc) => _fromFirestore(doc)).toList();
    } catch (e) {
      if (kDebugMode) {
        print('🔴 FirestoreTrainingAttendanceRepository: Failed to get attendances for training - $e');
      }
      rethrow;
    }
  }

  Future<List<TrainingAttendance>> getAttendancesForPlayer(String playerId) async {
    try {
      final snapshot = await _collection.where('playerId', isEqualTo: playerId).get();
      return snapshot.docs.map((doc) => _fromFirestore(doc)).toList();
    } catch (e) {
      if (kDebugMode) {
        print('🔴 FirestoreTrainingAttendanceRepository: Failed to get attendances for player - $e');
      }
      rethrow;
    }
  }

  Future<void> deleteAttendancesForTraining(String trainingId) async {
    try {
      final attendances = await getAttendancesForTraining(trainingId);
      for (final attendance in attendances) {
        await deleteAttendance(attendance.id);
      }
      if (kDebugMode) {
        print('🟢 FirestoreTrainingAttendanceRepository: Deleted all attendances for training $trainingId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('🔴 FirestoreTrainingAttendanceRepository: Failed to delete attendances for training - $e');
      }
      rethrow;
    }
  }

  // Real-time Streams
  Stream<List<TrainingAttendance>> attendancesStream() {
    return _collection.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => _fromFirestore(doc)).toList();
    });
  }

  Stream<List<TrainingAttendance>> attendancesForTrainingStream(String trainingId) {
    return _collection.where('trainingId', isEqualTo: trainingId).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => _fromFirestore(doc)).toList();
    });
  }

  Stream<List<TrainingAttendance>> attendancesForPlayerStream(String playerId) {
    return _collection.where('playerId', isEqualTo: playerId).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => _fromFirestore(doc)).toList();
    });
  }

  // Serialization
  Map<String, dynamic> _toFirestore(TrainingAttendance attendance) {
    return {
      'id': attendance.id,
      'trainingId': attendance.trainingId,
      'playerId': attendance.playerId,
      'status': attendance.status.name,
      'reason': attendance.reason,
      'arrivalTime': attendance.arrivalTime != null ? Timestamp.fromDate(attendance.arrivalTime!) : null,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  TrainingAttendance _fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return TrainingAttendance(
      id: data['id'] as String,
      trainingId: data['trainingId'] as String,
      playerId: data['playerId'] as String,
      status: TrainingAttendanceStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => TrainingAttendanceStatus.present,
      ),
      reason: data['reason'] as String?,
      arrivalTime: data['arrivalTime'] != null ? (data['arrivalTime'] as Timestamp).toDate() : null,
    );
  }
}
