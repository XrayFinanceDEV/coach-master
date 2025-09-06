// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'training.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TrainingAdapter extends TypeAdapter<Training> {
  @override
  final int typeId = 3;

  @override
  Training read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Training(
      id: fields[0] as String,
      teamId: fields[1] as String,
      date: fields[2] as DateTime,
      startTime: fields[3] as TimeOfDay,
      endTime: fields[4] as TimeOfDay,
      location: fields[5] as String,
      objectives: (fields[6] as List).cast<String>(),
      coachNotes: fields[7] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Training obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.teamId)
      ..writeByte(2)
      ..write(obj.date)
      ..writeByte(3)
      ..write(obj.startTime)
      ..writeByte(4)
      ..write(obj.endTime)
      ..writeByte(5)
      ..write(obj.location)
      ..writeByte(6)
      ..write(obj.objectives)
      ..writeByte(7)
      ..write(obj.coachNotes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TrainingAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
