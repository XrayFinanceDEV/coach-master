import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coachmaster/models/team.dart';
import 'package:coachmaster/core/repository_instances.dart';
import 'package:coachmaster/core/firestore_repository_providers.dart';

/// Global selected team state management with Firestore persistence
/// This ensures all screens use the same team consistently across devices
class SelectedTeamNotifier extends Notifier<String?> {
  @override
  String? build() {
    _loadSelectedTeam();
    return null;
  }

  /// Load the selected team from Firestore on startup
  Future<void> _loadSelectedTeam() async {
    try {
      final settingsRepo = ref.read(userSettingsRepositoryProvider);
      final teamId = await settingsRepo.getSelectedTeamId();

      if (teamId != null) {
        state = teamId;
        if (kDebugMode) {
          print('🎯 SelectedTeam: Loaded from Firestore: $teamId');
        }
      } else {
        // Auto-select first team if none is selected
        if (kDebugMode) {
          print('🎯 SelectedTeam: No team selected, attempting auto-select');
        }
        await _autoSelectFirstTeam();
      }
    } catch (e) {
      if (kDebugMode) {
        print('🔴 SelectedTeam: Failed to load from Firestore - $e');
      }
    }
  }

  /// Auto-select the first available team
  Future<void> _autoSelectFirstTeam() async {
    try {
      final teamRepo = ref.read(teamRepositoryProvider);
      final teams = await teamRepo.getTeams();

      if (teams.isNotEmpty) {
        final firstTeam = teams.first;
        await selectTeam(firstTeam.id);
        if (kDebugMode) {
          print('🎯 SelectedTeam: Auto-selected first team: ${firstTeam.name}');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('🔴 SelectedTeam: Failed to auto-select team - $e');
      }
    }
  }

  /// Set the selected team and persist it to Firestore
  Future<void> selectTeam(String teamId) async {
    state = teamId;

    try {
      final settingsRepo = ref.read(userSettingsRepositoryProvider);
      await settingsRepo.setSelectedTeamId(teamId);

      if (kDebugMode) {
        print('🎯 SelectedTeam: Selected and saved to Firestore: $teamId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('🔴 SelectedTeam: Failed to save to Firestore - $e');
      }
    }
  }

  /// Clear the selected team (useful for logout or team deletion)
  Future<void> clearTeam() async {
    state = null;

    try {
      final settingsRepo = ref.read(userSettingsRepositoryProvider);
      await settingsRepo.setSelectedTeamId(null);

      if (kDebugMode) {
        print('🎯 SelectedTeam: Cleared from Firestore');
      }
    } catch (e) {
      if (kDebugMode) {
        print('🔴 SelectedTeam: Failed to clear from Firestore - $e');
      }
    }
  }

  /// Get the selected season ID from Firestore
  Future<String?> getSelectedSeasonId() async {
    try {
      final settingsRepo = ref.read(userSettingsRepositoryProvider);
      return await settingsRepo.getSelectedSeasonId();
    } catch (e) {
      if (kDebugMode) {
        print('🔴 SelectedTeam: Failed to get season from Firestore - $e');
      }
      return null;
    }
  }

  /// Save the selected season ID to Firestore
  Future<void> setSelectedSeasonId(String seasonId) async {
    try {
      final settingsRepo = ref.read(userSettingsRepositoryProvider);
      await settingsRepo.setSelectedSeasonId(seasonId);

      if (kDebugMode) {
        print('🎯 SelectedTeam: Saved season to Firestore: $seasonId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('🔴 SelectedTeam: Failed to save season to Firestore - $e');
      }
    }
  }
}

/// Provider for the selected team ID (nullable)
final selectedTeamIdProvider = NotifierProvider<SelectedTeamNotifier, String?>(SelectedTeamNotifier.new);

/// Provider for the actual Team object (derived from selected team ID)
/// Uses StreamProvider for real-time updates from Firestore
final selectedTeamStreamProvider = StreamProvider<Team?>((ref) {
  final selectedTeamId = ref.watch(selectedTeamIdProvider);

  if (selectedTeamId == null) {
    return Stream.value(null);
  }

  // Get the team repository and create a stream
  final teamRepo = ref.watch(teamRepositoryProvider);
  return teamRepo.teamStream(selectedTeamId);
});

/// Legacy FutureProvider kept for backward compatibility
final selectedTeamProvider = FutureProvider<Team?>((ref) async {
  final selectedTeamId = ref.watch(selectedTeamIdProvider);

  if (selectedTeamId == null) {
    return null;
  }

  final teamRepo = ref.watch(teamRepositoryProvider);
  return await teamRepo.getTeam(selectedTeamId);
});

/// Synchronous helper to get team ID (for screens that need immediate access)
final selectedTeamIdSyncProvider = Provider<String?>((ref) {
  return ref.watch(selectedTeamIdProvider);
});

/// Auto-select the first available team if none is selected
/// This runs automatically when the app starts
final autoSelectTeamProvider = Provider<void>((ref) {
  // Watch the selected team ID to trigger loading
  ref.watch(selectedTeamIdProvider);
  return;
});
