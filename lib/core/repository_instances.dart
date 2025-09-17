import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coachmaster/models/player.dart';
import 'package:coachmaster/services/season_repository.dart';
import 'package:coachmaster/services/team_repository.dart';
import 'package:coachmaster/services/player_repository.dart';
import 'package:coachmaster/services/training_repository.dart';
import 'package:coachmaster/services/training_attendance_repository.dart';
import 'package:coachmaster/services/match_repository.dart';
import 'package:coachmaster/services/match_convocation_repository.dart';
import 'package:coachmaster/services/match_statistic_repository.dart';
import 'package:coachmaster/services/base_match_convocation_repository.dart';
import 'package:coachmaster/services/base_match_statistic_repository.dart';
import 'package:coachmaster/services/onboarding_repository.dart';
import 'package:coachmaster/services/user_repository.dart';
import 'package:coachmaster/services/note_repository.dart';
import 'package:coachmaster/services/sync_manager.dart';
import 'package:coachmaster/core/firebase_auth_providers.dart';

// Global repository instances
SeasonRepository? _seasonRepository;
TeamRepository? _teamRepository;
PlayerRepository? _playerRepository;
TrainingRepository? _trainingRepository;
TrainingAttendanceRepository? _trainingAttendanceRepository;
MatchRepository? _matchRepository;
BaseMatchConvocationRepository? _matchConvocationRepository;
BaseMatchStatisticRepository? _matchStatisticRepository;
OnboardingRepository? _onboardingRepository;
UserRepository? _userRepository;
NoteRepository? _noteRepository;

/// Initialize all repositories efficiently in parallel
Future<void> initializeRepositories({String? userId}) async {
  try {
    // Create all repository instances first
    _seasonRepository = SeasonRepository();
    _teamRepository = TeamRepository();
    _playerRepository = PlayerRepository();
    _trainingRepository = TrainingRepository();
    _trainingAttendanceRepository = TrainingAttendanceRepository();
    _matchRepository = MatchRepository();
    _matchConvocationRepository = MatchConvocationRepository();
    _matchStatisticRepository = MatchStatisticRepository();
    _onboardingRepository = OnboardingRepository();
    _userRepository = UserRepository();
    _noteRepository = NoteRepository();

    // Initialize all repositories in parallel to reduce startup time
    await Future.wait([
      _seasonRepository!.init(userId: userId),
      _teamRepository!.init(userId: userId),
      _playerRepository!.init(userId: userId),
      _trainingRepository!.init(userId: userId),
      _trainingAttendanceRepository!.init(), // TODO: Add userId support
      _matchRepository!.init(), // TODO: Add userId support
      _matchConvocationRepository!.init(), // TODO: Add userId support
      _matchStatisticRepository!.init(), // TODO: Add userId support
      _onboardingRepository!.init(), // Global, not user-specific
      _userRepository!.init(), // Global, not user-specific
      _noteRepository!.init(), // TODO: Add userId support
    ]);
  } catch (e) {
    // Handle initialization errors gracefully
    rethrow;
  }
}

/// Close all repositories (useful for user switching)
Future<void> closeRepositories() async {
  try {
    final futures = <Future<void>>[];

    // Only close repositories that are initialized
    if (_seasonRepository != null) {
      futures.add(_seasonRepository!.close());
    }
    if (_teamRepository != null) {
      futures.add(_teamRepository!.close());
    }
    if (_playerRepository != null) {
      futures.add(_playerRepository!.close());
    }
    if (_trainingRepository != null) {
      futures.add(_trainingRepository!.close());
    }

    // Wait for all close operations
    if (futures.isNotEmpty) {
      await Future.wait(futures);
    }

    // Reset repository references
    _seasonRepository = null;
    _teamRepository = null;
    _playerRepository = null;
    _trainingRepository = null;

  } catch (e) {
    // Handle close errors gracefully
    print('Error closing repositories: $e');
  }
}

/// Provider for user-specific repository reinitialization
final repositoryReInitProvider = FutureProvider.family<void, String>((ref, userId) async {
  try {
    // Check if repositories are already initialized for this user
    // Use a simple null check since we don't have isInitialized on all repos yet
    if (_seasonRepository != null) {
      print('🔄 Repositories already initialized, skipping reinitialization for user: $userId');
      return;
    }

    // Reinitialize with user-specific boxes
    await initializeRepositories(userId: userId);

    print('🔄 Repositories reinitialized for user: $userId');
  } catch (e) {
    print('❌ Error reinitializing repositories for user $userId: $e');
    rethrow;
  }
});

// Sync-aware repository providers that switch between local and sync repositories
// Returns SeasonRepository or SeasonSyncRepository (both have same interface)
final seasonRepositoryProvider = Provider<dynamic>((ref) {
  final authState = ref.watch(firebaseAuthProvider);

  // If user is authenticated with Firebase and SyncManager is initialized, use sync repository
  if (authState.isUsingFirebaseAuth &&
      !authState.isInitializing &&
      SyncManager.instance.isInitialized) {
    return SyncManager.instance.seasonRepository;
  }

  // Otherwise use local repository
  if (_seasonRepository == null) {
    throw Exception('SeasonRepository not initialized. Make sure to call initializeRepositories() first.');
  }
  return _seasonRepository;
});

// Returns TeamRepository or TeamSyncRepository (both have same interface)
final teamRepositoryProvider = Provider<dynamic>((ref) {
  final authState = ref.watch(firebaseAuthProvider);

  if (authState.isUsingFirebaseAuth &&
      !authState.isInitializing &&
      SyncManager.instance.isInitialized) {
    return SyncManager.instance.teamRepository;
  }

  if (_teamRepository == null) {
    throw Exception('TeamRepository not initialized. Make sure to call initializeRepositories() first.');
  }
  return _teamRepository;
});

// Returns PlayerRepository or PlayerSyncRepository (both have same interface)
final playerRepositoryProvider = Provider<dynamic>((ref) {
  final authState = ref.watch(firebaseAuthProvider);
  
  if (authState.isUsingFirebaseAuth && 
      !authState.isInitializing && 
      SyncManager.instance.isInitialized) {
    return SyncManager.instance.playerRepository;
  }
  
  return _playerRepository;
});

// Additional providers for forced refresh
final playerListProvider = Provider<List<Player>>((ref) {
  final repo = ref.watch(playerRepositoryProvider);
  return repo.getPlayers();
});
// Returns TrainingRepository or TrainingSyncRepository (both have same interface)  
final trainingRepositoryProvider = Provider<dynamic>((ref) {
  final authState = ref.watch(firebaseAuthProvider);
  
  if (authState.isUsingFirebaseAuth && 
      !authState.isInitializing && 
      SyncManager.instance.isInitialized) {
    return SyncManager.instance.trainingRepository;
  }
  
  return _trainingRepository;
});

final trainingAttendanceRepositoryProvider = Provider<TrainingAttendanceRepository>((ref) {
  if (_trainingAttendanceRepository == null) {
    throw Exception('TrainingAttendanceRepository not initialized. Make sure to call initializeRepositories() first.');
  }
  return _trainingAttendanceRepository!;
});

// Returns MatchRepository or MatchSyncRepository (both have same interface)
final matchRepositoryProvider = Provider<dynamic>((ref) {
  final authState = ref.watch(firebaseAuthProvider);
  
  if (authState.isUsingFirebaseAuth && 
      !authState.isInitializing && 
      SyncManager.instance.isInitialized) {
    return SyncManager.instance.matchRepository;
  }
  
  return _matchRepository;
});

final matchConvocationRepositoryProvider = Provider<BaseMatchConvocationRepository>((ref) {
  final authState = ref.watch(firebaseAuthProvider);

  if (authState.isUsingFirebaseAuth &&
      !authState.isInitializing &&
      SyncManager.instance.isInitialized) {
    return SyncManager.instance.matchConvocationRepository;
  }

  if (_matchConvocationRepository == null) {
    throw Exception('MatchConvocationRepository not initialized. Make sure to call initializeRepositories() first.');
  }
  return _matchConvocationRepository!;
});

final matchStatisticRepositoryProvider = Provider<BaseMatchStatisticRepository>((ref) {
  final authState = ref.watch(firebaseAuthProvider);

  if (authState.isUsingFirebaseAuth &&
      !authState.isInitializing &&
      SyncManager.instance.isInitialized) {
    return SyncManager.instance.matchStatisticRepository;
  }

  if (_matchStatisticRepository == null) {
    throw Exception('MatchStatisticRepository not initialized. Make sure to call initializeRepositories() first.');
  }
  return _matchStatisticRepository!;
});

final onboardingRepositoryProvider = Provider<OnboardingRepository>((ref) {
  if (_onboardingRepository == null) {
    throw Exception('OnboardingRepository not initialized. Make sure to call initializeRepositories() first.');
  }
  return _onboardingRepository!;
});
final userRepositoryProvider = Provider<UserRepository>((ref) {
  if (_userRepository == null) {
    throw Exception('UserRepository not initialized. Make sure to call initializeRepositories() first.');
  }
  return _userRepository!;
});

// Returns NoteRepository or NoteSyncRepository (both have same interface)
final noteRepositoryProvider = Provider<dynamic>((ref) {
  final authState = ref.watch(firebaseAuthProvider);
  
  if (authState.isUsingFirebaseAuth && 
      !authState.isInitializing && 
      SyncManager.instance.isInitialized) {
    return SyncManager.instance.noteRepository;
  }
  
  return _noteRepository;
});

// Onboarding status provider
final onboardingStatusProvider = Provider<bool>((ref) {
  final onboardingRepo = ref.watch(onboardingRepositoryProvider);
  return onboardingRepo.isOnboardingCompleted;
});

// Refresh counter for UI synchronization
class RefreshCounterNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void increment() {
    state++;
  }
}

final refreshCounterProvider = NotifierProvider<RefreshCounterNotifier, int>(() {
  return RefreshCounterNotifier();
});


// Reactive providers
final playersForTeamProvider = Provider.family<List<Player>, String>((ref, teamId) {
  final repo = ref.watch(playerRepositoryProvider);
  ref.watch(refreshCounterProvider); // Force rebuild when counter changes
  return repo.getPlayersForTeam(teamId);
});
