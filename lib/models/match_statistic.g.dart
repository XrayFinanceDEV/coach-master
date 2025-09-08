// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'match_statistic.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MatchStatisticAdapter extends TypeAdapter<MatchStatistic> {
  @override
  final int typeId = 8;

  @override
  MatchStatistic read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MatchStatistic(
      id: fields[0] as String,
      matchId: fields[1] as String,
      playerId: fields[2] as String,
      goals: fields[3] as int,
      assists: fields[4] as int,
      yellowCards: fields[5] as int,
      redCards: fields[6] as int,
      minutesPlayed: fields[7] as int,
      rating: fields[8] as double?,
      position: fields[9] as String?,
      notes: fields[10] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, MatchStatistic obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.matchId)
      ..writeByte(2)
      ..write(obj.playerId)
      ..writeByte(3)
      ..write(obj.goals)
      ..writeByte(4)
      ..write(obj.assists)
      ..writeByte(5)
      ..write(obj.yellowCards)
      ..writeByte(6)
      ..write(obj.redCards)
      ..writeByte(7)
      ..write(obj.minutesPlayed)
      ..writeByte(8)
      ..write(obj.rating)
      ..writeByte(9)
      ..write(obj.position)
      ..writeByte(10)
      ..write(obj.notes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MatchStatisticAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
