import 'package:coachmaster/models/note.dart';
import 'package:coachmaster/services/base_sync_repository.dart';
import 'package:coachmaster/services/firestore_sync_service.dart';

class NoteSyncRepository extends BaseSyncRepository<Note> {
  NoteSyncRepository({FirestoreSyncService? syncService}) 
    : super(
        boxName: 'notes',
        entityType: 'notes',
        syncService: syncService,
      );

  // Legacy methods for backward compatibility
  Future<void> init() async {
    if (!isInitialized) {
      throw Exception('NoteSyncRepository: Use initForUser() instead of init() for sync support');
    }
  }

  List<Note> getAllNotes() => getAll();
  Note? getNote(String id) => get(id);

  // Enhanced methods with sync support
  Future<void> addNote(Note note) async {
    await addWithSync(note);
  }

  Future<void> updateNote(Note note) async {
    final updatedNote = note.copyWith(updatedAt: DateTime.now());
    await updateWithSync(updatedNote);
  }

  Future<void> deleteNote(String id) async {
    await deleteWithSync(id);
  }

  // Query methods
  List<Note> getNotesForLinkedItem(String linkedId, {String? linkedType}) {
    final allNotes = getAllNotes();
    return allNotes.where((note) {
      final matchesId = note.linkedId == linkedId;
      if (linkedType != null) {
        return matchesId && note.linkedType == linkedType;
      }
      return matchesId;
    }).toList();
  }

  List<Note> getNotesForPlayer(String playerId) {
    return getNotesForLinkedItem(playerId, linkedType: 'player');
  }

  List<Note> getNotesForTraining(String trainingId) {
    return getNotesForLinkedItem(trainingId, linkedType: 'training');
  }

  List<Note> getNotesForMatch(String matchId) {
    return getNotesForLinkedItem(matchId, linkedType: 'match');
  }

  List<Note> getNotesByType(NoteType type) {
    final allNotes = getAllNotes();
    return allNotes.where((note) => note.type == type).toList();
  }

  Future<void> deleteNotesForLinkedItem(String linkedId, {String? linkedType}) async {
    final notesToDelete = getNotesForLinkedItem(linkedId, linkedType: linkedType);
    for (final note in notesToDelete) {
      await deleteWithSync(note.id);
    }
  }

  // Utility method to create a quick note
  Future<Note> createQuickNote({
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
    await addWithSync(note);
    return note;
  }

  // Implementation of abstract methods from BaseSyncRepository
  @override
  String getEntityId(Note item) => item.id;

  @override
  Map<String, dynamic> toMap(Note item) {
    return {
      'id': item.id,
      'content': item.content,
      'type': item.type.name,
      'linkedId': item.linkedId,
      'linkedType': item.linkedType,
      'createdAt': item.createdAt.toIso8601String(),
      'updatedAt': item.updatedAt.toIso8601String(),
    };
  }

  @override
  Note fromMap(Map<String, dynamic> map) {
    return Note(
      id: map['id'] as String,
      content: map['content'] as String,
      type: NoteType.values.firstWhere((e) => e.name == (map['type'] as String)),
      linkedId: map['linkedId'] as String?,
      linkedType: map['linkedType'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }
}