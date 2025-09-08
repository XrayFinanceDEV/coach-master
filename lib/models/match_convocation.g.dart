// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'match_convocation.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MatchConvocationAdapter extends TypeAdapter<MatchConvocation> {
  @override
  final int typeId = 7;

  @override
  MatchConvocation read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MatchConvocation(
      id: fields[0] as String,
      matchId: fields[1] as String,
      playerId: fields[2] as String,
      status: fields[3] as PlayerMatchStatus,
    );
  }

  @override
  void write(BinaryWriter writer, MatchConvocation obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.matchId)
      ..writeByte(2)
      ..write(obj.playerId)
      ..writeByte(3)
      ..write(obj.status);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MatchConvocationAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class PlayerMatchStatusAdapter extends TypeAdapter<PlayerMatchStatus> {
  @override
  final int typeId = 13;

  @override
  PlayerMatchStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return PlayerMatchStatus.convoked;
      case 1:
        return PlayerMatchStatus.playing;
      case 2:
        return PlayerMatchStatus.substitute;
      case 3:
        return PlayerMatchStatus.notPlaying;
      default:
        return PlayerMatchStatus.convoked;
    }
  }

  @override
  void write(BinaryWriter writer, PlayerMatchStatus obj) {
    switch (obj) {
      case PlayerMatchStatus.convoked:
        writer.writeByte(0);
        break;
      case PlayerMatchStatus.playing:
        writer.writeByte(1);
        break;
      case PlayerMatchStatus.substitute:
        writer.writeByte(2);
        break;
      case PlayerMatchStatus.notPlaying:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlayerMatchStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
