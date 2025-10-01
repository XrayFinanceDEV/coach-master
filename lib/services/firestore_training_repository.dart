import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:coachmaster/models/training.dart';

class FirestoreTrainingRepository {
  final String userId;
  final FirebaseFirestore _firestore;

  late final CollectionReference<Map<String, dynamic>> _collection;

  FirestoreTrainingRepository({
    required this.userId,
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance {
    _collection = _firestore.collection('users').doc(userId).collection('trainings');

    if (kDebugMode) {
      print('🔥 FirestoreTrainingRepository: Initialized for user $userId');
    }
  }

  Future<void> addTraining(Training training) async {
    try {
      await _collection.doc(training.id).set(_toFirestore(training));
      if (kDebugMode) {
        print('🟢 FirestoreTrainingRepository: Added training ${training.id}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('🔴 FirestoreTrainingRepository: Failed to add training - $e');
      }
      rethrow;
    }
  }

  Future<void> updateTraining(Training training) async {
    try {
      await _collection.doc(training.id).set(_toFirestore(training));
      if (kDebugMode) {
        print('🟢 FirestoreTrainingRepository: Updated training ${training.id}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('🔴 FirestoreTrainingRepository: Failed to update training - $e');
      }
      rethrow;
    }
  }

  Future<void> deleteTraining(String trainingId) async {
    try {
      await _collection.doc(trainingId).delete();
      if (kDebugMode) {
        print('🟢 FirestoreTrainingRepository: Deleted training $trainingId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('🔴 FirestoreTrainingRepository: Failed to delete training - $e');
      }
      rethrow;
    }
  }

  Future<Training?> getTraining(String trainingId) async {
    try {
      final doc = await _collection.doc(trainingId).get();
      if (!doc.exists) return null;
      return _fromFirestore(doc);
    } catch (e) {
      if (kDebugMode) {
        print('🔴 FirestoreTrainingRepository: Failed to get training - $e');
      }
      rethrow;
    }
  }

  Future<List<Training>> getTrainings() async {
    try {
      final snapshot = await _collection.orderBy('date', descending: true).get();
      return snapshot.docs.map((doc) => _fromFirestore(doc)).toList();
    } catch (e) {
      if (kDebugMode) {
        print('🔴 FirestoreTrainingRepository: Failed to get trainings - $e');
      }
      rethrow;
    }
  }

  Future<List<Training>> getTrainingsForTeam(String teamId) async {
    try {
      final snapshot = await _collection
          .where('teamId', isEqualTo: teamId)
          .orderBy('date', descending: true)
          .get();
      return snapshot.docs.map((doc) => _fromFirestore(doc)).toList();
    } catch (e) {
      if (kDebugMode) {
        print('🔴 FirestoreTrainingRepository: Failed to get trainings for team - $e');
      }
      rethrow;
    }
  }

  // Real-time Streams
  Stream<List<Training>> trainingsStream() {
    return _collection.orderBy('date', descending: true).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => _fromFirestore(doc)).toList();
    });
  }

  Stream<List<Training>> trainingsForTeamStream(String teamId) {
    return _collection
        .where('teamId', isEqualTo: teamId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => _fromFirestore(doc)).toList();
    });
  }

  Stream<Training?> trainingStream(String trainingId) {
    return _collection.doc(trainingId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return _fromFirestore(doc);
    });
  }

  // Serialization
  Map<String, dynamic> _toFirestore(Training training) {
    return {
      'id': training.id,
      'teamId': training.teamId,
      'date': Timestamp.fromDate(training.date),
      'startTime': '${training.startTime.hour}:${training.startTime.minute}',
      'endTime': '${training.endTime.hour}:${training.endTime.minute}',
      'location': training.location,
      'objectives': training.objectives,
      'coachNotes': training.coachNotes,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  Training _fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;

    final startTimeParts = (data['startTime'] as String).split(':');
    final endTimeParts = (data['endTime'] as String).split(':');

    // Handle both Timestamp and String date formats for backward compatibility
    DateTime date;
    final dateData = data['date'];
    if (dateData is Timestamp) {
      date = dateData.toDate();
    } else if (dateData is String) {
      date = DateTime.parse(dateData);
    } else {
      throw Exception('Invalid date format: $dateData');
    }

    return Training(
      id: data['id'] as String,
      teamId: data['teamId'] as String,
      date: date,
      startTime: TimeOfDay(
        hour: int.parse(startTimeParts[0]),
        minute: int.parse(startTimeParts[1]),
      ),
      endTime: TimeOfDay(
        hour: int.parse(endTimeParts[0]),
        minute: int.parse(endTimeParts[1]),
      ),
      location: data['location'] as String,
      objectives: List<String>.from(data['objectives'] as List),
      coachNotes: data['coachNotes'] as String?,
    );
  }
}
