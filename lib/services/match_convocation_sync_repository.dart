import 'package:coachmaster/models/match_convocation.dart';
import 'package:coachmaster/services/base_sync_repository.dart';
import 'package:coachmaster/services/firestore_sync_service.dart';
import 'package:coachmaster/services/base_match_convocation_repository.dart';

class MatchConvocationSyncRepository extends BaseSyncRepository<MatchConvocation> implements BaseMatchConvocationRepository {
  MatchConvocationSyncRepository({FirestoreSyncService? syncService}) 
    : super(
        boxName: 'matchConvocations',
        entityType: 'match_convocations',
        syncService: syncService,
      );

  // Legacy methods for backward compatibility
  @override
  Future<void> init() async {
    if (!isInitialized) {
      throw Exception('MatchConvocationSyncRepository: Use initForUser() instead of init() for sync support');
    }
  }

  @override
  List<MatchConvocation> getConvocations() => getAll();
  @override
  MatchConvocation? getConvocation(String id) => get(id);

  // Enhanced methods with sync support
  @override
  Future<void> addConvocation(MatchConvocation convocation) async {
    await addWithSync(convocation);
  }

  @override
  Future<void> updateConvocation(MatchConvocation convocation) async {
    await updateWithSync(convocation);
  }

  @override
  Future<void> deleteConvocation(String id) async {
    await deleteWithSync(id);
  }

  // Additional query methods
  @override
  List<MatchConvocation> getConvocationsForMatch(String matchId) {
    return getAll().where((conv) => conv.matchId == matchId).toList();
  }

  @override
  List<MatchConvocation> getConvocationsForPlayer(String playerId) {
    return getAll().where((conv) => conv.playerId == playerId).toList();
  }

  // Delete all convocations for a match (when match is deleted)
  @override
  Future<void> deleteConvocationsForMatch(String matchId) async {
    final matchConvocations = getConvocationsForMatch(matchId);
    for (final convocation in matchConvocations) {
      await deleteWithSync(convocation.id);
    }
  }

  // Implementation of abstract methods from BaseSyncRepository
  @override
  String getEntityId(MatchConvocation item) => item.id;

  @override
  Map<String, dynamic> toMap(MatchConvocation item) {
    return {
      'id': item.id,
      'matchId': item.matchId,
      'playerId': item.playerId,
      'status': item.status.index,
      'createdAt': DateTime.now().toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    };
  }

  @override
  MatchConvocation fromMap(Map<String, dynamic> map) {
    return MatchConvocation(
      id: map['id'] as String,
      matchId: map['matchId'] as String,
      playerId: map['playerId'] as String,
      status: PlayerMatchStatus.values[map['status'] as int],
    );
  }
}