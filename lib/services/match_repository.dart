import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coachmaster/models/match.dart';

class MatchRepository {
  late Box<Match> _matchBox;

  Future<void> init() async {
    _matchBox = await Hive.openBox<Match>('matches');
  }

  List<Match> getMatches() {
    return _matchBox.values.toList();
  }

  Match? getMatch(String id) {
    return _matchBox.get(id);
  }

  Future<void> addMatch(Match match) async {
    await _matchBox.put(match.id, match);
  }

  Future<void> updateMatch(Match match) async {
    await _matchBox.put(match.id, match);
  }

  Future<void> deleteMatch(String id) async {
    await _matchBox.delete(id);
  }

  List<Match> getMatchesForTeam(String teamId) {
    return _matchBox.values.where((match) => match.teamId == teamId).toList();
  }

  List<Match> getMatchesForSeason(String seasonId) {
    return _matchBox.values.where((match) => match.seasonId == seasonId).toList();
  }
}

final matchRepositoryProvider = Provider((ref) => MatchRepository());
