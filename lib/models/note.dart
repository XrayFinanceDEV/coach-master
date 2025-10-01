enum NoteType {
  player,
  training,
  general,
  match,
}

class Note {
  final String id;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;
  final NoteType type;
  final String? linkedId; // playerId, trainingId, etc.
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

  // JSON serialization for Firestore
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'type': type.name,
      'linkedId': linkedId,
      'linkedType': linkedType,
    };
  }

  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(
      id: json['id'] as String,
      content: json['content'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      type: NoteType.values.firstWhere((e) => e.name == json['type']),
      linkedId: json['linkedId'] as String?,
      linkedType: json['linkedType'] as String?,
    );
  }
}
