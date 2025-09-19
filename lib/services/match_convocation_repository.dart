import 'package:hive_flutter/hive_flutter.dart';
import 'package:coachmaster/models/match_convocation.dart';
import 'package:coachmaster/services/base_match_convocation_repository.dart';

class MatchConvocationRepository implements BaseMatchConvocationRepository {
  late Box<MatchConvocation> _convocationBox;

  @override
  Future<void> init({String? userId}) async {
    final boxName = userId != null ? 'matchConvocations_$userId' : 'matchConvocations';
    _convocationBox = await Hive.openBox<MatchConvocation>(boxName);
  }

  @override
  List<MatchConvocation> getConvocations() {
    return _convocationBox.values.toList();
  }

  @override
  MatchConvocation? getConvocation(String id) {
    return _convocationBox.get(id);
  }

  @override
  Future<void> addConvocation(MatchConvocation convocation) async {
    await _convocationBox.put(convocation.id, convocation);
  }

  @override
  Future<void> updateConvocation(MatchConvocation convocation) async {
    await _convocationBox.put(convocation.id, convocation);
  }

  @override
  Future<void> deleteConvocation(String id) async {
    await _convocationBox.delete(id);
  }

  @override
  List<MatchConvocation> getConvocationsForMatch(String matchId) {
    return _convocationBox.values.where((conv) => conv.matchId == matchId).toList();
  }

  @override
  List<MatchConvocation> getConvocationsForPlayer(String playerId) {
    return _convocationBox.values.where((conv) => conv.playerId == playerId).toList();
  }

  // Delete all convocations for a match (when match is deleted)
  @override
  Future<void> deleteConvocationsForMatch(String matchId) async {
    final matchConvocations = getConvocationsForMatch(matchId);
    for (final convocation in matchConvocations) {
      await _convocationBox.delete(convocation.id);
    }
  }
}
