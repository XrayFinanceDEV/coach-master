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

class MatchStatusAdapter extends TypeAdapter<MatchStatus> {
  @override
  final int typeId = 11;

  @override
  MatchStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return MatchStatus.scheduled;
      case 1:
        return MatchStatus.live;
      case 2:
        return MatchStatus.completed;
      default:
        return MatchStatus.scheduled;
    }
  }

  @override
  void write(BinaryWriter writer, MatchStatus obj) {
    switch (obj) {
      case MatchStatus.scheduled:
        writer.writeByte(0);
        break;
      case MatchStatus.live:
        writer.writeByte(1);
        break;
      case MatchStatus.completed:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MatchStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class MatchResultAdapter extends TypeAdapter<MatchResult> {
  @override
  final int typeId = 12;

  @override
  MatchResult read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return MatchResult.win;
      case 1:
        return MatchResult.loss;
      case 2:
        return MatchResult.draw;
      case 3:
        return MatchResult.none;
      default:
        return MatchResult.win;
    }
  }

  @override
  void write(BinaryWriter writer, MatchResult obj) {
    switch (obj) {
      case MatchResult.win:
        writer.writeByte(0);
        break;
      case MatchResult.loss:
        writer.writeByte(1);
        break;
      case MatchResult.draw:
        writer.writeByte(2);
        break;
      case MatchResult.none:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MatchResultAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
