import 'package:flutter/foundation.dart';
import 'package:coachmaster/models/team.dart';
import 'package:coachmaster/services/base_sync_repository.dart';

class TeamSyncRepository extends BaseSyncRepository<Team> {
  TeamSyncRepository({super.syncService})
    : super(
        boxName: 'teams',
        entityType: 'teams',
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

  /// Clean up duplicate teams (keeps the latest entry for each unique ID)
  Future<void> cleanupDuplicateTeams() async {
    if (kDebugMode) {
      print('🟢 TeamSyncRepository: Starting cleanup of duplicate teams');
    }

    try {
      final uniqueTeams = <String, Team>{};
      final keysToDelete = <dynamic>[];

      // Safely collect all teams and find duplicates
      for (final key in box.keys) {
        try {
          final team = box.get(key);
          if (team != null) {
            if (uniqueTeams.containsKey(team.id)) {
              // Mark this key for deletion (it's a duplicate)
              keysToDelete.add(key);
              if (kDebugMode) {
                print('🟢 TeamSyncRepository: Found duplicate team ${team.id}, marking key $key for deletion');
              }
            } else {
              uniqueTeams[team.id] = team;
            }
          }
        } catch (e) {
          if (kDebugMode) {
            print('🟢 TeamSyncRepository: Error processing key $key: $e');
          }
          // Mark corrupted entries for deletion
          keysToDelete.add(key);
        }
      }

      // Delete duplicate/corrupted keys
      for (final key in keysToDelete) {
        try {
          await box.delete(key);
          if (kDebugMode) {
            print('🟢 TeamSyncRepository: Deleted duplicate/corrupted key $key');
          }
        } catch (e) {
          if (kDebugMode) {
            print('🟢 TeamSyncRepository: Error deleting key $key: $e');
          }
        }
      }

      if (kDebugMode) {
        print('🟢 TeamSyncRepository: Cleanup completed. Deleted ${keysToDelete.length} duplicate/corrupted entries');
      }
    } catch (e) {
      if (kDebugMode) {
        print('🟢 TeamSyncRepository: Error during cleanup: $e');
      }
      // Simply log the error - don't try complex recovery
    }
  }

  /// Clear all corrupted data and reinitialize (emergency fix)
  Future<void> clearCorruptedData() async {
    try {
      if (kDebugMode) {
        print('🟢 TeamSyncRepository: Clearing all corrupted data');
      }

      await box.clear();

      if (kDebugMode) {
        print('🟢 TeamSyncRepository: All data cleared successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('🟢 TeamSyncRepository: Error clearing corrupted data: $e');
      }
      // Simply log the error - don't try complex recovery
    }
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