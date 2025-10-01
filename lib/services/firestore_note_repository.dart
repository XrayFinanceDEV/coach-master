import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:coachmaster/models/note.dart';

class FirestoreNoteRepository {
  final String userId;
  final FirebaseFirestore _firestore;

  late final CollectionReference<Map<String, dynamic>> _collection;

  FirestoreNoteRepository({
    required this.userId,
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance {
    _collection = _firestore.collection('users').doc(userId).collection('notes');

    if (kDebugMode) {
      print('🔥 FirestoreNoteRepository: Initialized for user $userId');
    }
  }

  Future<void> addNote(Note note) async {
    try {
      await _collection.doc(note.id).set(_toFirestore(note));
      if (kDebugMode) {
        print('🟢 FirestoreNoteRepository: Added note ${note.id}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('🔴 FirestoreNoteRepository: Failed to add note - $e');
      }
      rethrow;
    }
  }

  Future<void> updateNote(Note note) async {
    try {
      await _collection.doc(note.id).set(_toFirestore(note));
      if (kDebugMode) {
        print('🟢 FirestoreNoteRepository: Updated note ${note.id}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('🔴 FirestoreNoteRepository: Failed to update note - $e');
      }
      rethrow;
    }
  }

  Future<void> deleteNote(String noteId) async {
    try {
      await _collection.doc(noteId).delete();
      if (kDebugMode) {
        print('🟢 FirestoreNoteRepository: Deleted note $noteId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('🔴 FirestoreNoteRepository: Failed to delete note - $e');
      }
      rethrow;
    }
  }

  Future<Note?> getNote(String noteId) async {
    try {
      final doc = await _collection.doc(noteId).get();
      if (!doc.exists) return null;
      return _fromFirestore(doc);
    } catch (e) {
      if (kDebugMode) {
        print('🔴 FirestoreNoteRepository: Failed to get note - $e');
      }
      rethrow;
    }
  }

  Future<List<Note>> getNotes() async {
    try {
      final snapshot = await _collection.orderBy('createdAt', descending: true).get();
      return snapshot.docs.map((doc) => _fromFirestore(doc)).toList();
    } catch (e) {
      if (kDebugMode) {
        print('🔴 FirestoreNoteRepository: Failed to get notes - $e');
      }
      rethrow;
    }
  }

  Future<List<Note>> getNotesForLinkedItem(String linkedId, {String? linkedType}) async {
    try {
      var query = _collection.where('linkedId', isEqualTo: linkedId);

      if (linkedType != null) {
        query = query.where('linkedType', isEqualTo: linkedType);
      }

      final snapshot = await query.orderBy('createdAt', descending: true).get();
      return snapshot.docs.map((doc) => _fromFirestore(doc)).toList();
    } catch (e) {
      if (kDebugMode) {
        print('🔴 FirestoreNoteRepository: Failed to get notes for linked item - $e');
      }
      rethrow;
    }
  }

  Future<List<Note>> getNotesForPlayer(String playerId) async {
    return getNotesForLinkedItem(playerId, linkedType: 'player');
  }

  Future<List<Note>> getNotesForTraining(String trainingId) async {
    return getNotesForLinkedItem(trainingId, linkedType: 'training');
  }

  Future<List<Note>> getNotesForMatch(String matchId) async {
    return getNotesForLinkedItem(matchId, linkedType: 'match');
  }

  Future<void> createQuickNote({
    required String content,
    required NoteType type,
    String? linkedId,
    String? linkedType,
  }) async {
    final note = Note.create(
      content: content,
      type: type,
      linkedId: linkedId,
      linkedType: linkedType,
    );
    await addNote(note);
  }

  Future<void> deleteNotesForLinkedItem(String linkedId, {String? linkedType}) async {
    try {
      final notes = await getNotesForLinkedItem(linkedId, linkedType: linkedType);
      for (final note in notes) {
        await deleteNote(note.id);
      }
      if (kDebugMode) {
        print('🟢 FirestoreNoteRepository: Deleted all notes for linked item $linkedId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('🔴 FirestoreNoteRepository: Failed to delete notes for linked item - $e');
      }
      rethrow;
    }
  }

  // Real-time Streams
  Stream<List<Note>> notesStream() {
    return _collection.orderBy('createdAt', descending: true).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => _fromFirestore(doc)).toList();
    });
  }

  Stream<List<Note>> notesForLinkedItemStream(String linkedId, {String? linkedType}) {
    var query = _collection.where('linkedId', isEqualTo: linkedId);

    if (linkedType != null) {
      query = query.where('linkedType', isEqualTo: linkedType);
    }

    return query.orderBy('createdAt', descending: true).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => _fromFirestore(doc)).toList();
    });
  }

  Stream<List<Note>> notesForPlayerStream(String playerId) {
    return notesForLinkedItemStream(playerId, linkedType: 'player');
  }

  Stream<List<Note>> notesForTrainingStream(String trainingId) {
    return notesForLinkedItemStream(trainingId, linkedType: 'training');
  }

  Stream<List<Note>> notesForMatchStream(String matchId) {
    return notesForLinkedItemStream(matchId, linkedType: 'match');
  }

  // Serialization
  Map<String, dynamic> _toFirestore(Note note) {
    return {
      'id': note.id,
      'content': note.content,
      'type': note.type.name,
      'linkedId': note.linkedId,
      'linkedType': note.linkedType,
      'createdAt': Timestamp.fromDate(note.createdAt),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  Note _fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Note(
      id: data['id'] as String,
      content: data['content'] as String,
      type: NoteType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => NoteType.general,
      ),
      linkedId: data['linkedId'] as String?,
      linkedType: data['linkedType'] as String?,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null ? (data['updatedAt'] as Timestamp).toDate() : DateTime.now(),
    );
  }
}
