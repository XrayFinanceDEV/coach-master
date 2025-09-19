import 'package:hive/hive.dart';
import 'package:coachmaster/models/note.dart';

class NoteRepository {
  static const String boxName = 'notes';
  Box<Note>? _box;

  Future<void> init({String? userId}) async {
    final actualBoxName = userId != null ? '${boxName}_$userId' : boxName;
    if (_box?.isOpen != true) {
      _box = await Hive.openBox<Note>(actualBoxName);
    }
  }

  List<Note> getAllNotes() {
    return _box?.values.toList() ?? [];
  }

  Note? getNote(String id) {
    return _box?.get(id);
  }

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

  Future<void> addNote(Note note) async {
    await _box?.put(note.id, note);
  }

  Future<void> updateNote(Note note) async {
    final updatedNote = note.copyWith(updatedAt: DateTime.now());
    await _box?.put(updatedNote.id, updatedNote);
  }

  Future<void> deleteNote(String id) async {
    await _box?.delete(id);
  }

  Future<void> deleteNotesForLinkedItem(String linkedId, {String? linkedType}) async {
    final notesToDelete = getNotesForLinkedItem(linkedId, linkedType: linkedType);
    for (final note in notesToDelete) {
      await deleteNote(note.id);
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
    await addNote(note);
    return note;
  }
}