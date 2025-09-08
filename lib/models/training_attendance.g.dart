// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'training_attendance.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TrainingAttendanceAdapter extends TypeAdapter<TrainingAttendance> {
  @override
  final int typeId = 5;

  @override
  TrainingAttendance read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TrainingAttendance(
      id: fields[0] as String,
      trainingId: fields[1] as String,
      playerId: fields[2] as String,
      status: fields[3] as TrainingAttendanceStatus,
      reason: fields[4] as String?,
      arrivalTime: fields[5] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, TrainingAttendance obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.trainingId)
      ..writeByte(2)
      ..write(obj.playerId)
      ..writeByte(3)
      ..write(obj.status)
      ..writeByte(4)
      ..write(obj.reason)
      ..writeByte(5)
      ..write(obj.arrivalTime);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TrainingAttendanceAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class TrainingAttendanceStatusAdapter
    extends TypeAdapter<TrainingAttendanceStatus> {
  @override
  final int typeId = 10;

  @override
  TrainingAttendanceStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return TrainingAttendanceStatus.present;
      case 1:
        return TrainingAttendanceStatus.absent;
      case 2:
        return TrainingAttendanceStatus.late;
      default:
        return TrainingAttendanceStatus.present;
    }
  }

  @override
  void write(BinaryWriter writer, TrainingAttendanceStatus obj) {
    switch (obj) {
      case TrainingAttendanceStatus.present:
        writer.writeByte(0);
        break;
      case TrainingAttendanceStatus.absent:
        writer.writeByte(1);
        break;
      case TrainingAttendanceStatus.late:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TrainingAttendanceStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
