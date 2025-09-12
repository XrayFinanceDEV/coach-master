import 'package:hive/hive.dart';

part 'note.g.dart';

@HiveType(typeId: 15)
enum NoteType {
  @HiveField(0)
  player,
  @HiveField(1)
  training,
  @HiveField(2)
  general,
  @HiveField(3)
  match,
}

@HiveType(typeId: 16)
class Note {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String content;
  @HiveField(2)
  final DateTime createdAt;
  @HiveField(3)
  final DateTime updatedAt;
  @HiveField(4)
  final NoteType type;
  @HiveField(5)
  final String? linkedId; // playerId, trainingId, etc.
  @HiveField(6)
  final String? linkedType; // 'player', 'training', etc.

  Note({
    required this.id,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    required this.type,
    this.linkedId,
    this.linkedType,
  });

  factory Note.create({
    required String content,
    required NoteType type,
    String? linkedId,
    String? linkedType,
  }) {
    final now = DateTime.now();
    return Note(
      id: 'note_${now.millisecondsSinceEpoch}',
      content: content,
      createdAt: now,
      updatedAt: now,
      type: type,
      linkedId: linkedId,
      linkedType: linkedType,
    );
  }

  Note copyWith({
    String? id,
    String? content,
    DateTime? createdAt,
    DateTime? updatedAt,
    NoteType? type,
    String? linkedId,
    String? linkedType,
  }) {
    return Note(
      id: id ?? this.id,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      type: type ?? this.type,
      linkedId: linkedId ?? this.linkedId,
      linkedType: linkedType ?? this.linkedType,
    );
  }
}