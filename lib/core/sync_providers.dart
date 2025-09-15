import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coachmaster/services/sync_manager.dart';
import 'package:coachmaster/services/season_sync_repository.dart';
import 'package:coachmaster/services/team_sync_repository.dart';
import 'package:coachmaster/services/player_sync_repository.dart';
import 'package:coachmaster/services/training_sync_repository.dart';
import 'package:coachmaster/services/match_sync_repository.dart';
import 'package:coachmaster/models/sync_status.dart';
import 'package:coachmaster/models/season.dart';
import 'package:coachmaster/models/team.dart';
import 'package:coachmaster/models/player.dart';
import 'package:coachmaster/models/training.dart';
import 'package:coachmaster/models/match.dart';

// Sync Manager Provider
final syncManagerProvider = Provider<SyncManager>((ref) {
  return SyncManager.instance;
});

// Sync Status Stream Provider
final syncStatusProvider = StreamProvider<SyncStatus>((ref) {
  final syncManager = ref.watch(syncManagerProvider);
  return syncManager.syncStatusStream;
});

// Sync Status Info Provider
final syncInfoProvider = Provider<({bool isOnline, int pendingSyncCount, bool isInitialized})>((ref) {
  final syncManager = ref.watch(syncManagerProvider);
  return (
    isOnline: syncManager.isOnline,
    pendingSyncCount: syncManager.pendingSyncCount,
    isInitialized: syncManager.isInitialized,
  );
});

// Sync-enabled Repository Providers
final seasonSyncRepositoryProvider = Provider<SeasonSyncRepository>((ref) {
  final syncManager = ref.watch(syncManagerProvider);
  if (!syncManager.isInitialized) {
    throw Exception('SyncManager not initialized');
  }
  return syncManager.seasonRepository;
});

final teamSyncRepositoryProvider = Provider<TeamSyncRepository>((ref) {
  final syncManager = ref.watch(syncManagerProvider);
  if (!syncManager.isInitialized) {
    throw Exception('SyncManager not initialized');
  }
  return syncManager.teamRepository;
});

final playerSyncRepositoryProvider = Provider<PlayerSyncRepository>((ref) {
  final syncManager = ref.watch(syncManagerProvider);
  if (!syncManager.isInitialized) {
    throw Exception('SyncManager not initialized');
  }
  return syncManager.playerRepository;
});

final trainingSyncRepositoryProvider = Provider<TrainingSyncRepository>((ref) {
  final syncManager = ref.watch(syncManagerProvider);
  if (!syncManager.isInitialized) {
    throw Exception('SyncManager not initialized');
  }
  return syncManager.trainingRepository;
});

final matchSyncRepositoryProvider = Provider<MatchSyncRepository>((ref) {
  final syncManager = ref.watch(syncManagerProvider);
  if (!syncManager.isInitialized) {
    throw Exception('SyncManager not initialized');
  }
  return syncManager.matchRepository;
});

// Sync-enabled data providers (replaces the old repository providers when sync is active)
final syncedSeasonsProvider = Provider<List<Season>>((ref) {
  try {
    final repository = ref.watch(seasonSyncRepositoryProvider);
    return repository.getSeasons();
  } catch (e) {
    // Fallback to empty list if sync not initialized
    return <Season>[];
  }
});

final syncedTeamsProvider = Provider<List<Team>>((ref) {
  try {
    final repository = ref.watch(teamSyncRepositoryProvider);
    return repository.getTeams();
  } catch (e) {
    return <Team>[];
  }
});

final syncedPlayersProvider = Provider<List<Player>>((ref) {
  try {
    final repository = ref.watch(playerSyncRepositoryProvider);
    return repository.getPlayers();
  } catch (e) {
    return <Player>[];
  }
});

final syncedTrainingsProvider = Provider<List<Training>>((ref) {
  try {
    final repository = ref.watch(trainingSyncRepositoryProvider);
    return repository.getTrainings();
  } catch (e) {
    return <Training>[];
  }
});

final syncedMatchesProvider = Provider<List<Match>>((ref) {
  try {
    final repository = ref.watch(matchSyncRepositoryProvider);
    return repository.getMatches();
  } catch (e) {
    return <Match>[];
  }
});

final currentSeasonSyncProvider = Provider<Season?>((ref) {
  try {
    final repository = ref.watch(seasonSyncRepositoryProvider);
    return repository.getCurrentSeason();
  } catch (e) {
    // Fallback to null if sync not initialized
    return null;
  }
});

// Sync Actions Provider (for UI to trigger sync operations)
final syncActionsProvider = Provider<SyncActions>((ref) {
  final syncManager = ref.watch(syncManagerProvider);
  return SyncActions(syncManager);
});

class SyncActions {
  final SyncManager _syncManager;
  
  SyncActions(this._syncManager);
  
  Future<void> performFullSync() async {
    await _syncManager.performFullSync();
  }
  
  Future<void> syncAllToFirestore() async {
    await _syncManager.syncAllToFirestore();
  }
  
  bool get canSync => _syncManager.isInitialized && _syncManager.isOnline;
}