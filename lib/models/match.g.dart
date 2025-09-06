// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'match.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MatchAdapter extends TypeAdapter<Match> {
  @override
  final int typeId = 6;

  @override
  Match read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Match(
      id: fields[0] as String,
      teamId: fields[1] as String,
      seasonId: fields[2] as String,
      opponent: fields[3] as String,
      date: fields[4] as DateTime,
      location: fields[5] as String,
      isHome: fields[6] as bool,
      goalsFor: fields[7] as int?,
      goalsAgainst: fields[8] as int?,
      result: fields[9] as MatchResult,
      status: fields[10] as MatchStatus,
      tactics: (fields[11] as Map?)?.cast<String, dynamic>(),
    );
  }

  @override
  void write(BinaryWriter writer, Match obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.teamId)
      ..writeByte(2)
      ..write(obj.seasonId)
      ..writeByte(3)
      ..write(obj.opponent)
      ..writeByte(4)
      ..write(obj.date)
      ..writeByte(5)
      ..write(obj.location)
      ..writeByte(6)
      ..write(obj.isHome)
      ..writeByte(7)
      ..write(obj.goalsFor)
      ..writeByte(8)
      ..write(obj.goalsAgainst)
      ..writeByte(9)
      ..write(obj.result)
      ..writeByte(10)
      ..write(obj.status)
      ..writeByte(11)
      ..write(obj.tactics);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MatchAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
