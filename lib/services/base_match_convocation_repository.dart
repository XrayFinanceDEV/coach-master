import 'package:coachmaster/models/match_convocation.dart';

abstract class BaseMatchConvocationRepository {
  // Legacy methods for backward compatibility
  Future<void> init({String? userId});
  
  List<MatchConvocation> getConvocations();
  MatchConvocation? getConvocation(String id);
  
  // Enhanced methods with sync support
  Future<void> addConvocation(MatchConvocation convocation);
  Future<void> updateConvocation(MatchConvocation convocation);
  Future<void> deleteConvocation(String id);
  
  // Additional query methods
  List<MatchConvocation> getConvocationsForMatch(String matchId);
  List<MatchConvocation> getConvocationsForPlayer(String playerId);
  
  // Delete all convocations for a match (when match is deleted)
  Future<void> deleteConvocationsForMatch(String matchId);
}