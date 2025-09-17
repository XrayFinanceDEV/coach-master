import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:coachmaster/services/firestore_sync_service.dart';
import 'package:coachmaster/services/season_sync_repository.dart';
import 'package:coachmaster/services/team_sync_repository.dart';
import 'package:coachmaster/services/player_sync_repository.dart';
import 'package:coachmaster/services/training_sync_repository.dart';
import 'package:coachmaster/services/match_sync_repository.dart';
import 'package:coachmaster/services/match_convocation_sync_repository.dart';
import 'package:coachmaster/services/match_statistic_sync_repository.dart';
import 'package:coachmaster/services/note_sync_repository.dart';
import 'package:coachmaster/models/sync_status.dart';

class SyncManager {
  static SyncManager? _instance;
  static SyncManager get instance => _instance ??= SyncManager._internal();
  SyncManager._internal();

  FirestoreSyncService? _syncService;
  String? _currentUserId;
  bool _isInitialized = false;

  // Sync-enabled repositories
  SeasonSyncRepository? _seasonRepository;
  TeamSyncRepository? _teamRepository;
  PlayerSyncRepository? _playerRepository;
  TrainingSyncRepository? _trainingRepository;
  MatchSyncRepository? _matchRepository;
  MatchConvocationSyncRepository? _matchConvocationRepository;
  MatchStatisticSyncRepository? _matchStatisticRepository;
  NoteSyncRepository? _noteRepository;

  // Streams
  StreamController<SyncStatus> _syncStatusController = StreamController<SyncStatus>.broadcast();
  Stream<SyncStatus> get syncStatusStream => _syncStatusController.stream;

  // Initialize sync manager for a specific user
  Future<void> initializeForUser(User firebaseUser) async {
    if (_isInitialized && _currentUserId == firebaseUser.uid) {
      return; // Already initialized for this user
    }

    if (kDebugMode) {
      print('🔄 SyncManager: Initializing for user ${firebaseUser.email}');
    }

    _currentUserId = firebaseUser.uid;
    
    // Initialize sync service
    _syncService = FirestoreSyncService();
    await _syncService!.initialize(firebaseUser.uid);

    // Initialize sync-enabled repositories
    _seasonRepository = SeasonSyncRepository(syncService: _syncService);
    await _seasonRepository!.initForUser(firebaseUser.uid);

    _teamRepository = TeamSyncRepository(syncService: _syncService);
    await _teamRepository!.initForUser(firebaseUser.uid);

    _playerRepository = PlayerSyncRepository(syncService: _syncService);
    await _playerRepository!.initForUser(firebaseUser.uid);

    _trainingRepository = TrainingSyncRepository(syncService: _syncService);
    await _trainingRepository!.initForUser(firebaseUser.uid);

    _matchRepository = MatchSyncRepository(syncService: _syncService);
    await _matchRepository!.initForUser(firebaseUser.uid);

    _matchConvocationRepository = MatchConvocationSyncRepository(syncService: _syncService);
    await _matchConvocationRepository!.initForUser(firebaseUser.uid);

    _matchStatisticRepository = MatchStatisticSyncRepository(syncService: _syncService);
    await _matchStatisticRepository!.initForUser(firebaseUser.uid);

    _noteRepository = NoteSyncRepository(syncService: _syncService);
    await _noteRepository!.initForUser(firebaseUser.uid);

    // Forward sync status from sync service
    _syncService!.syncStatusStream.listen((status) {
      _syncStatusController.add(status);
    });

    _isInitialized = true;
    _syncStatusController.add(SyncStatus.ready);

    if (kDebugMode) {
      print('🟢 SyncManager: Initialized successfully');
    }
  }

  // Clean up when user signs out
  Future<void> cleanup() async {
    if (kDebugMode) {
      print('🔄 SyncManager: Cleaning up');
    }

    await _syncService?.dispose();
    await _seasonRepository?.close();
    await _teamRepository?.close();
    await _playerRepository?.close();
    await _trainingRepository?.close();
    await _matchRepository?.close();
    await _matchConvocationRepository?.close();
    await _matchStatisticRepository?.close();
    await _noteRepository?.close();

    _syncService = null;
    _seasonRepository = null;
    _teamRepository = null;
    _playerRepository = null;
    _trainingRepository = null;
    _matchRepository = null;
    _matchConvocationRepository = null;
    _matchStatisticRepository = null;
    _noteRepository = null;
    _currentUserId = null;
    _isInitialized = false;

    _syncStatusController.add(SyncStatus.ready);

    if (kDebugMode) {
      print('🟢 SyncManager: Cleaned up');
    }
  }

  // Repository getters
  SeasonSyncRepository get seasonRepository {
    if (_seasonRepository == null || !_isInitialized) {
      throw Exception('SyncManager not initialized. Call initializeForUser() first.');
    }
    return _seasonRepository!;
  }

  TeamSyncRepository get teamRepository {
    if (_teamRepository == null || !_isInitialized) {
      throw Exception('SyncManager not initialized. Call initializeForUser() first.');
    }
    return _teamRepository!;
  }

  PlayerSyncRepository get playerRepository {
    if (_playerRepository == null || !_isInitialized) {
      throw Exception('SyncManager not initialized. Call initializeForUser() first.');
    }
    return _playerRepository!;
  }

  TrainingSyncRepository get trainingRepository {
    if (_trainingRepository == null || !_isInitialized) {
      throw Exception('SyncManager not initialized. Call initializeForUser() first.');
    }
    return _trainingRepository!;
  }

  MatchSyncRepository get matchRepository {
    if (_matchRepository == null || !_isInitialized) {
      throw Exception('SyncManager not initialized. Call initializeForUser() first.');
    }
    return _matchRepository!;
  }

  MatchConvocationSyncRepository get matchConvocationRepository {
    if (_matchConvocationRepository == null || !_isInitialized) {
      throw Exception('SyncManager not initialized. Call initializeForUser() first.');
    }
    return _matchConvocationRepository!;
  }

  MatchStatisticSyncRepository get matchStatisticRepository {
    if (_matchStatisticRepository == null || !_isInitialized) {
      throw Exception('SyncManager not initialized. Call initializeForUser() first.');
    }
    return _matchStatisticRepository!;
  }

  NoteSyncRepository get noteRepository {
    if (_noteRepository == null || !_isInitialized) {
      throw Exception('SyncManager not initialized. Call initializeForUser() first.');
    }
    return _noteRepository!;
  }

  // Sync operations
  Future<void> performFullSync() async {
    if (_syncService == null || !_isInitialized) {
      if (kDebugMode) {
        print('🔄 SyncManager: Cannot sync - not initialized');
      }
      return;
    }

    if (kDebugMode) {
      print('🔄 SyncManager: Starting full sync');
    }

    await _syncService!.performFullSync();
  }

  // Force download from Firestore across all repositories (useful for cross-device sync)
  Future<void> forceDownloadAll() async {
    if (_syncService == null || !_isInitialized) {
      if (kDebugMode) {
        print('🔄 SyncManager: Cannot force download - not initialized');
      }
      return;
    }

    if (kDebugMode) {
      print('🔄 SyncManager: Force downloading all data from Firestore');
    }

    try {
      await _seasonRepository?.forceDownloadFromFirestore();
      await _teamRepository?.forceDownloadFromFirestore();
      await _playerRepository?.forceDownloadFromFirestore();
      await _trainingRepository?.forceDownloadFromFirestore();
      await _matchRepository?.forceDownloadFromFirestore();
      await _matchConvocationRepository?.forceDownloadFromFirestore();
      await _matchStatisticRepository?.forceDownloadFromFirestore();
      await _noteRepository?.forceDownloadFromFirestore();

      if (kDebugMode) {
        print('🟢 SyncManager: Force download completed');
      }
    } catch (e) {
      if (kDebugMode) {
        print('🔴 SyncManager: Force download failed - $e');
      }
    }
  }

  // Sync all local data to Firestore (useful for migration)
  Future<void> syncAllToFirestore() async {
    if (!_isInitialized) {
      throw Exception('SyncManager not initialized');
    }

    if (kDebugMode) {
      print('🔄 SyncManager: Syncing all local data to Firestore');
    }

    // Sync all repositories
    await _seasonRepository?.syncAllToFirestore();
    await _teamRepository?.syncAllToFirestore();
    await _playerRepository?.syncAllToFirestore();
    await _trainingRepository?.syncAllToFirestore();
    await _matchRepository?.syncAllToFirestore();
    await _matchConvocationRepository?.syncAllToFirestore();
    await _matchStatisticRepository?.syncAllToFirestore();
    await _noteRepository?.syncAllToFirestore();

    if (kDebugMode) {
      print('🟢 SyncManager: All local data synced to Firestore');
    }
  }

  // Status getters
  bool get isInitialized => _isInitialized;
  bool get isOnline => _syncService?.isOnline ?? false;
  int get pendingSyncCount => _syncService?.pendingSyncCount ?? 0;
  String? get currentUserId => _currentUserId;

  // Dispose
  Future<void> dispose() async {
    await cleanup();
    await _syncStatusController.close();
  }
}