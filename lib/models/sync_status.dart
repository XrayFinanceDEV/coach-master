import 'package:hive/hive.dart';

part 'sync_status.g.dart';

@HiveType(typeId: 99) // Using a high type ID to avoid conflicts
enum SyncStatus {
  @HiveField(0)
  synced,
  
  @HiveField(1) 
  pending,
  
  @HiveField(2)
  uploading,
  
  @HiveField(3)
  conflict,
  
  @HiveField(4)
  failed,
  
  @HiveField(5)
  ready,
  
  @HiveField(6)
  syncing,
  
  @HiveField(7)
  error
}

extension SyncStatusExtension on SyncStatus {
  String get displayName {
    switch (this) {
      case SyncStatus.synced:
        return 'Synced';
      case SyncStatus.pending:
        return 'Pending';
      case SyncStatus.uploading:
        return 'Uploading';
      case SyncStatus.conflict:
        return 'Conflict';
      case SyncStatus.failed:
        return 'Failed';
      case SyncStatus.ready:
        return 'Ready';
      case SyncStatus.syncing:
        return 'Syncing';
      case SyncStatus.error:
        return 'Error';
    }
  }
  
  bool get isSync => this == SyncStatus.synced;
  bool get needsSync => this == SyncStatus.pending || this == SyncStatus.failed;
  bool get inProgress => this == SyncStatus.uploading || this == SyncStatus.syncing;
}