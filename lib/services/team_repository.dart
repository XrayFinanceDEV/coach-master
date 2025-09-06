import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coachmaster/models/team.dart';

class TeamRepository {
  late Box<Team> _teamBox;

  Future<void> init() async {
    _teamBox = await Hive.openBox<Team>('teams');
  }

  List<Team> getTeams() {
    return _teamBox.values.toList();
  }

  Team? getTeam(String id) {
    return _teamBox.get(id);
  }

  Future<void> addTeam(Team team) async {
    await _teamBox.put(team.id, team);
  }

  Future<void> updateTeam(Team team) async {
    await _teamBox.put(team.id, team);
  }

  Future<void> deleteTeam(String id) async {
    await _teamBox.delete(id);
  }

  List<Team> getTeamsForSeason(String seasonId) {
    return _teamBox.values.where((team) => team.seasonId == seasonId).toList();
  }
}

final teamRepositoryProvider = Provider((ref) => TeamRepository());
