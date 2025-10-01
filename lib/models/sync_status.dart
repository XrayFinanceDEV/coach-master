enum SyncStatus {
  synced,
  pending,
  uploading,
  conflict,
  failed,
  ready,
  syncing,
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
