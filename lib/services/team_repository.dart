import 'package:hive_flutter/hive_flutter.dart';
import 'package:coachmaster/models/team.dart';
import 'package:flutter/foundation.dart';

class TeamRepository {
  late Box<Team> _teamBox;
  String? _currentUserId;

  Future<void> init({String? userId}) async {
    _currentUserId = userId;
    // Use user-specific box to prevent cross-user data conflicts
    final boxName = userId != null ? 'teams_$userId' : 'teams';
    _teamBox = await Hive.openBox<Team>(boxName);
    
    if (kDebugMode) {
      print('🟢 TeamRepository: Initialized with box $boxName');
    }
  }

  List<Team> getTeams() {
    final teams = <Team>[];
    try {
      for (final key in _teamBox.keys) {
        try {
          final team = _teamBox.get(key);
          if (team != null && team is Team) {
            teams.add(team);
          }
        } catch (e) {
          if (kDebugMode) {
            print('🟢 TeamRepository: Error reading team at key $key in getTeams: $e');
          }
          continue;
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('🟢 TeamRepository: Error in getTeams: $e');
      }
    }
    return teams;
  }

  Team? getTeam(String id) {
    try {
      final team = _teamBox.get(id);
      if (team != null && team is Team) {
        return team;
      }
    } catch (e) {
      if (kDebugMode) {
        print('🟢 TeamRepository: Error getting team $id: $e');
      }
    }
    return null;
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
    // Filter out duplicates by team ID to prevent dropdown assertion errors
    final teamsMap = <String, Team>{};
    
    try {
      for (final key in _teamBox.keys) {
        try {
          final team = _teamBox.get(key);
          // Type check to ensure we have a valid Team object
          if (team != null && team is Team && team.seasonId == seasonId) {
            teamsMap[team.id] = team;
          }
        } catch (e) {
          if (kDebugMode) {
            print('🟢 TeamRepository: Error reading team at key $key: $e');
          }
          // Skip this entry and continue
          continue;
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('🟢 TeamRepository: Error in getTeamsForSeason: $e');
      }
      // Return empty list if we can't read teams
      return <Team>[];
    }
    
    return teamsMap.values.toList();
  }

  /// Clean up duplicate teams (keeps the latest entry for each unique ID)
  Future<void> cleanupDuplicateTeams() async {
    try {
      if (kDebugMode) {
        print('🟢 TeamRepository: Starting cleanup of duplicate teams');
      }
      
      final uniqueTeams = <String, Team>{};
      final keysToDelete = <dynamic>[];
      
      // Safely collect all teams and find duplicates
      for (final key in _teamBox.keys) {
        try {
          final team = _teamBox.get(key);
          if (team != null && team is Team) {
            if (uniqueTeams.containsKey(team.id)) {
              // Mark this key for deletion (it's a duplicate)
              keysToDelete.add(key);
              if (kDebugMode) {
                print('🟢 TeamRepository: Found duplicate team ${team.id}, marking key $key for deletion');
              }
            } else {
              uniqueTeams[team.id] = team;
            }
          } else if (team != null) {
            // Invalid team data - mark for deletion
            keysToDelete.add(key);
            if (kDebugMode) {
              print('🟢 TeamRepository: Found invalid team data at key $key, marking for deletion');
            }
          }
        } catch (e) {
          // If we can't read this entry, mark it for deletion
          keysToDelete.add(key);
          if (kDebugMode) {
            print('🟢 TeamRepository: Error reading team at key $key: $e, marking for deletion');
          }
        }
      }
      
      // Delete problematic entries
      for (final key in keysToDelete) {
        try {
          await _teamBox.delete(key);
          if (kDebugMode) {
            print('🟢 TeamRepository: Deleted problematic entry at key $key');
          }
        } catch (e) {
          if (kDebugMode) {
            print('🟢 TeamRepository: Error deleting key $key: $e');
          }
        }
      }
      
      // Re-save all unique teams with their proper IDs as keys
      if (uniqueTeams.isNotEmpty) {
        await _teamBox.clear();
        for (final team in uniqueTeams.values) {
          await _teamBox.put(team.id, team);
        }
        if (kDebugMode) {
          print('🟢 TeamRepository: Cleanup completed, ${uniqueTeams.length} unique teams preserved');
        }
      } else {
        if (kDebugMode) {
          print('🟢 TeamRepository: No valid teams found during cleanup');
        }
      }
      
    } catch (e) {
      if (kDebugMode) {
        print('🟢 TeamRepository: Error during cleanup: $e');
      }
      // If cleanup fails entirely, try to close and reopen the box
      try {
        await _teamBox.close();
        final boxName = _currentUserId != null ? 'teams_${_currentUserId}' : 'teams';
        _teamBox = await Hive.openBox<Team>(boxName);
        if (kDebugMode) {
          print('🟢 TeamRepository: Reopened box after cleanup error');
        }
      } catch (reopenError) {
        if (kDebugMode) {
          print('🟢 TeamRepository: Error reopening box: $reopenError');
        }
      }
    }
  }

  /// Close the current box (useful for user switching)
  Future<void> close() async {
    try {
      await _teamBox.close();
      if (kDebugMode) {
        print('🟢 TeamRepository: Closed');
      }
    } catch (e) {
      if (kDebugMode) {
        print('🟢 TeamRepository: Error closing box: $e');
      }
    }
  }

  /// Clear all corrupted data and reinitialize (emergency fix)
  Future<void> clearCorruptedData() async {
    try {
      if (kDebugMode) {
        print('🟢 TeamRepository: Clearing all corrupted data');
      }
      
      await _teamBox.clear();
      
      if (kDebugMode) {
        print('🟢 TeamRepository: All data cleared successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('🟢 TeamRepository: Error clearing corrupted data: $e');
      }
      
      // If clear fails, try to close and reopen the box
      try {
        await _teamBox.close();
        final boxName = _currentUserId != null ? 'teams_${_currentUserId}' : 'teams';
        _teamBox = await Hive.openBox<Team>(boxName);
        await _teamBox.clear();
        if (kDebugMode) {
          print('🟢 TeamRepository: Reopened and cleared box after error');
        }
      } catch (reopenError) {
        if (kDebugMode) {
          print('🟢 TeamRepository: Failed to reopen and clear: $reopenError');
        }
      }
    }
  }
}
