import 'package:coachmaster/models/player.dart';
import 'package:coachmaster/services/base_sync_repository.dart';
import 'package:coachmaster/services/firestore_sync_service.dart';

class PlayerSyncRepository extends BaseSyncRepository<Player> {
  PlayerSyncRepository({FirestoreSyncService? syncService}) 
    : super(
        boxName: 'players',
        entityType: 'players',
        syncService: syncService,
      );

  // Legacy methods for backward compatibility
  Future<void> init() async {
    if (!isInitialized) {
      throw Exception('PlayerSyncRepository: Use initForUser() instead of init() for sync support');
    }
  }

  List<Player> getPlayers() => getAll();
  Player? getPlayer(String id) => get(id);

  // Enhanced methods with sync support
  Future<void> addPlayer(Player player) async {
    await addWithSync(player);
  }

  Future<void> updatePlayer(Player player) async {
    await updateWithSync(player);
  }

  Future<void> deletePlayer(String id) async {
    await deleteWithSync(id);
  }

  // Additional query methods
  List<Player> getPlayersForTeam(String teamId) {
    return getAll().where((player) => player.teamId == teamId).toList();
  }

  List<Player> getPlayersByPosition(String position) {
    return getAll().where((player) => player.position.toLowerCase() == position.toLowerCase()).toList();
  }

  List<Player> getTopScorers({int limit = 10}) {
    final players = getAll();
    players.sort((a, b) => b.goals.compareTo(a.goals));
    return players.take(limit).toList();
  }

  List<Player> getTopAssists({int limit = 10}) {
    final players = getAll();
    players.sort((a, b) => b.assists.compareTo(a.assists));
    return players.take(limit).toList();
  }

  // Implementation of abstract methods from BaseSyncRepository
  @override
  String getEntityId(Player item) => item.id;

  @override
  Map<String, dynamic> toMap(Player item) {
    return {
      'id': item.id,
      'teamId': item.teamId,
      'firstName': item.firstName,
      'lastName': item.lastName,
      'position': item.position,
      'preferredFoot': item.preferredFoot,
      'birthDate': item.birthDate.toIso8601String(),
      'photoPath': item.photoPath,
      'medicalInfo': item.medicalInfo,
      'emergencyContact': item.emergencyContact,
      'goals': item.goals,
      'assists': item.assists,
      'yellowCards': item.yellowCards,
      'redCards': item.redCards,
      'totalMinutes': item.totalMinutes,
      'avgRating': item.avgRating,
      'absences': item.absences,
    };
  }

  @override
  Player fromMap(Map<String, dynamic> map) {
    return Player(
      id: map['id'] as String,
      teamId: map['teamId'] as String,
      firstName: map['firstName'] as String,
      lastName: map['lastName'] as String,
      position: map['position'] as String,
      preferredFoot: map['preferredFoot'] as String,
      birthDate: DateTime.parse(map['birthDate'] as String),
      photoPath: map['photoPath'] as String?,
      medicalInfo: map['medicalInfo'] as Map<String, dynamic>?,
      emergencyContact: map['emergencyContact'] as Map<String, dynamic>?,
      goals: map['goals'] as int? ?? 0,
      assists: map['assists'] as int? ?? 0,
      yellowCards: map['yellowCards'] as int? ?? 0,
      redCards: map['redCards'] as int? ?? 0,
      totalMinutes: map['totalMinutes'] as int? ?? 0,
      avgRating: map['avgRating'] as double?,
      absences: map['absences'] as int? ?? 0,
    );
  }
}