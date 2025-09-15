import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coachmaster/core/sync_providers.dart';
import 'package:coachmaster/core/repository_instances.dart';
import 'package:coachmaster/models/season.dart';
import 'package:coachmaster/models/team.dart';
import 'package:coachmaster/models/player.dart';
import 'package:coachmaster/models/training.dart';
import 'package:coachmaster/models/match.dart';

// Sync-aware providers that automatically choose between sync and legacy repositories

final adaptiveSeasonProvider = Provider<List<Season>>((ref) {
  final syncManager = ref.watch(syncManagerProvider);
  
  if (syncManager.isInitialized) {
    // Use sync-enabled repository
    return ref.watch(syncedSeasonsProvider);
  } else {
    // Fallback to legacy repository
    final repo = ref.watch(seasonRepositoryProvider);
    return repo.getSeasons();
  }
});

final adaptiveTeamProvider = Provider<List<Team>>((ref) {
  final syncManager = ref.watch(syncManagerProvider);
  
  if (syncManager.isInitialized) {
    return ref.watch(syncedTeamsProvider);
  } else {
    final repo = ref.watch(teamRepositoryProvider);
    return repo.getTeams();
  }
});

final adaptivePlayerProvider = Provider<List<Player>>((ref) {
  final syncManager = ref.watch(syncManagerProvider);
  
  if (syncManager.isInitialized) {
    return ref.watch(syncedPlayersProvider);
  } else {
    final repo = ref.watch(playerRepositoryProvider);
    return repo.getPlayers();
  }
});

final adaptiveTrainingProvider = Provider<List<Training>>((ref) {
  final syncManager = ref.watch(syncManagerProvider);
  
  if (syncManager.isInitialized) {
    return ref.watch(syncedTrainingsProvider);
  } else {
    final repo = ref.watch(trainingRepositoryProvider);
    return repo.getTrainings();
  }
});

final adaptiveMatchProvider = Provider<List<Match>>((ref) {
  final syncManager = ref.watch(syncManagerProvider);
  
  if (syncManager.isInitialized) {
    return ref.watch(syncedMatchesProvider);
  } else {
    final repo = ref.watch(matchRepositoryProvider);
    return repo.getMatches();
  }
});

// Team-specific providers that work with current selected team
final adaptiveTeamPlayersProvider = Provider.family<List<Player>, String>((ref, teamId) {
  final syncManager = ref.watch(syncManagerProvider);
  
  if (syncManager.isInitialized) {
    final repository = ref.watch(playerSyncRepositoryProvider);
    return repository.getPlayersForTeam(teamId);
  } else {
    final repository = ref.watch(playerRepositoryProvider);
    return repository.getPlayersForTeam(teamId);
  }
});

final adaptiveTeamTrainingsProvider = Provider.family<List<Training>, String>((ref, teamId) {
  final syncManager = ref.watch(syncManagerProvider);
  
  if (syncManager.isInitialized) {
    final repository = ref.watch(trainingSyncRepositoryProvider);
    return repository.getTrainingsForTeam(teamId);
  } else {
    final repository = ref.watch(trainingRepositoryProvider);
    return repository.getTrainingsForTeam(teamId);
  }
});

final adaptiveTeamMatchesProvider = Provider.family<List<Match>, String>((ref, teamId) {
  final syncManager = ref.watch(syncManagerProvider);
  
  if (syncManager.isInitialized) {
    final repository = ref.watch(matchSyncRepositoryProvider);
    return repository.getMatchesForTeam(teamId);
  } else {
    final repository = ref.watch(matchRepositoryProvider);
    return repository.getMatchesForTeam(teamId);
  }
});

// Sync status helpers
final isSyncEnabledProvider = Provider<bool>((ref) {
  final syncManager = ref.watch(syncManagerProvider);
  return syncManager.isInitialized;
});

final syncStatsProvider = Provider<Map<String, dynamic>>((ref) {
  final syncManager = ref.watch(syncManagerProvider);
  final syncInfo = ref.watch(syncInfoProvider);
  
  return {
    'isEnabled': syncManager.isInitialized,
    'isOnline': syncInfo.isOnline,
    'pendingSync': syncInfo.pendingSyncCount,
    'status': syncManager.isInitialized ? 'Firebase Sync Active' : 'Local Storage Only',
  };
});