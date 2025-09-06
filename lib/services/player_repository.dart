import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coachmaster/models/player.dart';

class PlayerRepository {
  late Box<Player> _playerBox;

  Future<void> init() async {
    _playerBox = await Hive.openBox<Player>('players');
  }

  List<Player> getPlayers() {
    return _playerBox.values.toList();
  }

  Player? getPlayer(String id) {
    return _playerBox.get(id);
  }

  Future<void> addPlayer(Player player) async {
    await _playerBox.put(player.id, player);
  }

  Future<void> updatePlayer(Player player) async {
    await _playerBox.put(player.id, player);
  }

  Future<void> deletePlayer(String id) async {
    await _playerBox.delete(id);
  }

  List<Player> getPlayersForTeam(String teamId) {
    return _playerBox.values.where((player) => player.teamId == teamId).toList();
  }
}

final playerRepositoryProvider = Provider((ref) => PlayerRepository());
