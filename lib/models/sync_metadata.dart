class SyncMetadata {
  final String id;
  final String entityType; // 'season', 'team', 'player', etc.
  final String entityId;
  final DateTime lastModified;
  final DateTime? lastSynced;
  final bool needsSync;
  final bool isDeleted;
  final String? userId; // Firebase user ID
  final Map<String, dynamic>? conflictData; // For conflict resolution

  const SyncMetadata({
    required this.id,
    required this.entityType,
    required this.entityId,
    required this.lastModified,
    this.lastSynced,
    this.needsSync = true,
    this.isDeleted = false,
    this.userId,
    this.conflictData,
  });

  factory SyncMetadata.create({
    required String entityType,
    required String entityId,
    required String userId,
    bool isDeleted = false,
  }) {
    return SyncMetadata(
      id: '${entityType}_${entityId}_sync',
      entityType: entityType,
      entityId: entityId,
      lastModified: DateTime.now(),
      needsSync: true,
      isDeleted: isDeleted,
      userId: userId,
    );
  }

  SyncMetadata copyWith({
    String? id,
    String? entityType,
    String? entityId,
    DateTime? lastModified,
    DateTime? lastSynced,
    bool? needsSync,
    bool? isDeleted,
    String? userId,
    Map<String, dynamic>? conflictData,
  }) {
    return SyncMetadata(
      id: id ?? this.id,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      lastModified: lastModified ?? this.lastModified,
      lastSynced: lastSynced ?? this.lastSynced,
      needsSync: needsSync ?? this.needsSync,
      isDeleted: isDeleted ?? this.isDeleted,
      userId: userId ?? this.userId,
      conflictData: conflictData ?? this.conflictData,
    );
  }

  // Mark as synced
  SyncMetadata markSynced() {
    return copyWith(
      lastSynced: DateTime.now(),
      needsSync: false,
      conflictData: null,
    );
  }

  // Mark as needs sync
  SyncMetadata markNeedsSync() {
    return copyWith(
      lastModified: DateTime.now(),
      needsSync: true,
    );
  }

  // Mark as deleted and needs sync
  SyncMetadata markDeleted() {
    return copyWith(
      lastModified: DateTime.now(),
      needsSync: true,
      isDeleted: true,
    );
  }

  @override
  String toString() {
    return 'SyncMetadata(id: $id, entityType: $entityType, entityId: $entityId, needsSync: $needsSync, isDeleted: $isDeleted)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is SyncMetadata &&
            runtimeType == other.runtimeType &&
            id == other.id &&
            entityType == other.entityType &&
            entityId == other.entityId;
  }

  @override
  int get hashCode {
    return id.hashCode ^ entityType.hashCode ^ entityId.hashCode;
  }

  // JSON serialization for Firestore
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'entityType': entityType,
      'entityId': entityId,
      'lastModified': lastModified.toIso8601String(),
      'lastSynced': lastSynced?.toIso8601String(),
      'needsSync': needsSync,
      'isDeleted': isDeleted,
      'userId': userId,
      'conflictData': conflictData,
    };
  }

  factory SyncMetadata.fromJson(Map<String, dynamic> json) {
    return SyncMetadata(
      id: json['id'] as String,
      entityType: json['entityType'] as String,
      entityId: json['entityId'] as String,
      lastModified: DateTime.parse(json['lastModified'] as String),
      lastSynced: json['lastSynced'] != null ? DateTime.parse(json['lastSynced'] as String) : null,
      needsSync: json['needsSync'] as bool,
      isDeleted: json['isDeleted'] as bool,
      userId: json['userId'] as String?,
      conflictData: json['conflictData'] as Map<String, dynamic>?,
    );
  }
}

enum SyncOperation {
  create,
  update,
  delete,
}

class PendingSyncOperation {
  final String id;
  final String entityType;
  final String entityId;
  final SyncOperation operation;
  final DateTime timestamp;
  final Map<String, dynamic>? entityData; // Serialized entity
  final String userId;
  final int retryCount;

  const PendingSyncOperation({
    required this.id,
    required this.entityType,
    required this.entityId,
    required this.operation,
    required this.timestamp,
    this.entityData,
    required this.userId,
    this.retryCount = 0,
  });

  factory PendingSyncOperation.create({
    required String entityType,
    required String entityId,
    required SyncOperation operation,
    required String userId,
    Map<String, dynamic>? entityData,
  }) {
    return PendingSyncOperation(
      id: '${entityType}_${entityId}_${operation.name}_${DateTime.now().millisecondsSinceEpoch}',
      entityType: entityType,
      entityId: entityId,
      operation: operation,
      timestamp: DateTime.now(),
      entityData: entityData,
      userId: userId,
    );
  }

  PendingSyncOperation incrementRetry() {
    return PendingSyncOperation(
      id: id,
      entityType: entityType,
      entityId: entityId,
      operation: operation,
      timestamp: timestamp,
      entityData: entityData,
      userId: userId,
      retryCount: retryCount + 1,
    );
  }

  @override
  String toString() {
    return 'PendingSyncOperation(id: $id, entityType: $entityType, operation: ${operation.name}, retryCount: $retryCount)';
  }

  // JSON serialization for Firestore
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'entityType': entityType,
      'entityId': entityId,
      'operation': operation.name,
      'timestamp': timestamp.toIso8601String(),
      'entityData': entityData,
      'userId': userId,
      'retryCount': retryCount,
    };
  }

  factory PendingSyncOperation.fromJson(Map<String, dynamic> json) {
    return PendingSyncOperation(
      id: json['id'] as String,
      entityType: json['entityType'] as String,
      entityId: json['entityId'] as String,
      operation: SyncOperation.values.firstWhere((e) => e.name == json['operation']),
      timestamp: DateTime.parse(json['timestamp'] as String),
      entityData: json['entityData'] as Map<String, dynamic>?,
      userId: json['userId'] as String,
      retryCount: (json['retryCount'] as num?)?.toInt() ?? 0,
    );
  }
}
