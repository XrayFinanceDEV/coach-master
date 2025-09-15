import 'package:coachmaster/models/team.dart';
import 'package:coachmaster/services/base_sync_repository.dart';
import 'package:coachmaster/services/firestore_sync_service.dart';

class TeamSyncRepository extends BaseSyncRepository<Team> {
  TeamSyncRepository({FirestoreSyncService? syncService}) 
    : super(
        boxName: 'teams',
        entityType: 'teams',
        syncService: syncService,
      );

  // Legacy methods for backward compatibility
  Future<void> init() async {
    if (!isInitialized) {
      throw Exception('TeamSyncRepository: Use initForUser() instead of init() for sync support');
    }
  }

  List<Team> getTeams() => getAll();
  Team? getTeam(String id) => get(id);

  // Enhanced methods with sync support
  Future<void> addTeam(Team team) async {
    await addWithSync(team);
  }

  Future<void> updateTeam(Team team) async {
    await updateWithSync(team);
  }

  Future<void> deleteTeam(String id) async {
    await deleteWithSync(id);
  }

  // Additional query methods
  List<Team> getTeamsForSeason(String seasonId) {
    return getAll().where((team) => team.seasonId == seasonId).toList();
  }

  Team? getTeamForSeason(String seasonId) {
    final teams = getTeamsForSeason(seasonId);
    return teams.isNotEmpty ? teams.first : null;
  }

  // Implementation of abstract methods from BaseSyncRepository
  @override
  String getEntityId(Team item) => item.id;

  @override
  Map<String, dynamic> toMap(Team item) {
    return {
      'id': item.id,
      'seasonId': item.seasonId,
      'name': item.name,
      'description': item.description,
      'logoPath': item.logoPath,
    };
  }

  @override
  Team fromMap(Map<String, dynamic> map) {
    return Team(
      id: map['id'] as String,
      seasonId: map['seasonId'] as String,
      name: map['name'] as String,
      description: map['description'] as String?,
      logoPath: map['logoPath'] as String?,
    );
  }
}