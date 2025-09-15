// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sync_status.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SyncStatusAdapter extends TypeAdapter<SyncStatus> {
  @override
  final int typeId = 99;

  @override
  SyncStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return SyncStatus.synced;
      case 1:
        return SyncStatus.pending;
      case 2:
        return SyncStatus.uploading;
      case 3:
        return SyncStatus.conflict;
      case 4:
        return SyncStatus.failed;
      case 5:
        return SyncStatus.ready;
      case 6:
        return SyncStatus.syncing;
      case 7:
        return SyncStatus.error;
      default:
        return SyncStatus.synced;
    }
  }

  @override
  void write(BinaryWriter writer, SyncStatus obj) {
    switch (obj) {
      case SyncStatus.synced:
        writer.writeByte(0);
        break;
      case SyncStatus.pending:
        writer.writeByte(1);
        break;
      case SyncStatus.uploading:
        writer.writeByte(2);
        break;
      case SyncStatus.conflict:
        writer.writeByte(3);
        break;
      case SyncStatus.failed:
        writer.writeByte(4);
        break;
      case SyncStatus.ready:
        writer.writeByte(5);
        break;
      case SyncStatus.syncing:
        writer.writeByte(6);
        break;
      case SyncStatus.error:
        writer.writeByte(7);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SyncStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
