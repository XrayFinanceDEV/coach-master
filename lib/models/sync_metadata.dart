import 'package:hive/hive.dart';

part 'sync_metadata.g.dart';

@HiveType(typeId: 20)
class SyncMetadata {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String entityType; // 'season', 'team', 'player', etc.
  
  @HiveField(2)
  final String entityId;
  
  @HiveField(3)
  final DateTime lastModified;
  
  @HiveField(4)
  final DateTime? lastSynced;
  
  @HiveField(5)
  final bool needsSync;
  
  @HiveField(6)
  final bool isDeleted;
  
  @HiveField(7)
  final String? userId; // Firebase user ID
  
  @HiveField(8)
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
}

@HiveType(typeId: 22)
enum SyncOperation {
  @HiveField(0)
  create,
  @HiveField(1)
  update,
  @HiveField(2)
  delete,
}

@HiveType(typeId: 21)
class PendingSyncOperation {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String entityType;
  
  @HiveField(2)
  final String entityId;
  
  @HiveField(3)
  final SyncOperation operation;
  
  @HiveField(4)
  final DateTime timestamp;
  
  @HiveField(5)
  final Map<String, dynamic>? entityData; // Serialized entity
  
  @HiveField(6)
  final String userId;
  
  @HiveField(7)
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
}