import 'package:hive_flutter/hive_flutter.dart';
import 'package:coachmaster/models/match_convocation.dart';

class MatchConvocationRepository {
  late Box<MatchConvocation> _convocationBox;

  Future<void> init() async {
    _convocationBox = await Hive.openBox<MatchConvocation>('matchConvocations');
  }

  List<MatchConvocation> getConvocations() {
    return _convocationBox.values.toList();
  }

  MatchConvocation? getConvocation(String id) {
    return _convocationBox.get(id);
  }

  Future<void> addConvocation(MatchConvocation convocation) async {
    await _convocationBox.put(convocation.id, convocation);
  }

  Future<void> updateConvocation(MatchConvocation convocation) async {
    await _convocationBox.put(convocation.id, convocation);
  }

  Future<void> deleteConvocation(String id) async {
    await _convocationBox.delete(id);
  }

  List<MatchConvocation> getConvocationsForMatch(String matchId) {
    return _convocationBox.values.where((conv) => conv.matchId == matchId).toList();
  }

  List<MatchConvocation> getConvocationsForPlayer(String playerId) {
    return _convocationBox.values.where((conv) => conv.playerId == playerId).toList();
  }

  // Delete all convocations for a match (when match is deleted)
  Future<void> deleteConvocationsForMatch(String matchId) async {
    final matchConvocations = getConvocationsForMatch(matchId);
    for (final convocation in matchConvocations) {
      await _convocationBox.delete(convocation.id);
    }
  }
}
