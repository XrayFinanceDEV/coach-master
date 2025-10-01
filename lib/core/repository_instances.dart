import 'package:flutter/foundation.dart';
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
      _trainingAttendanceRepository!.init(userId: userId),
      _matchRepository!.init(userId: userId),
      _matchConvocationRepository!.init(userId: userId),
      _matchStatisticRepository!.init(userId: userId),
      _onboardingRepository!.init(), // Global, not user-specific
      _userRepository!.init(), // Global, not user-specific
      _noteRepository!.init(userId: userId),
    ]);

    // Mark repositories as initialized
    _repositoriesInitialized = true;

    if (kDebugMode) {
      print('🔧 Repository initialization completed successfully');
    }
  } catch (e) {
    // Handle initialization errors gracefully
    _repositoriesInitialized = false;
    if (kDebugMode) {
      print('🔧 Repository initialization failed: $e');
    }
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

    // Reset repository references and initialization flag
    _seasonRepository = null;
    _teamRepository = null;
    _playerRepository = null;
    _trainingRepository = null;
    _repositoriesInitialized = false;

  } catch (e) {
    // Handle close errors gracefully
    if (kDebugMode) {
      print('Error closing repositories: $e');
    }
  }
}

/// Provider for user-specific repository reinitialization
final repositoryReInitProvider = FutureProvider.family<void, String>((ref, userId) async {
  try {
    // Check if repositories are already initialized for this user
    // Use a simple null check since we don't have isInitialized on all repos yet
    if (_seasonRepository != null) {
      if (kDebugMode) {
        print('🔄 Repositories already initialized, skipping reinitialization for user: $userId');
      }
      return;
    }

    // Reinitialize with user-specific boxes
    await initializeRepositories(userId: userId);

    if (kDebugMode) {
      print('🔄 Repositories reinitialized for user: $userId');
    }
  } catch (e) {
    if (kDebugMode) {
      print('❌ Error reinitializing repositories for user $userId: $e');
    }
    rethrow;
  }
});

// Initialization tracking
bool _repositoriesInitialized = false;

// Initialization tracking provider
final repositoriesInitializedProvider = Provider<bool>((ref) {
  return _repositoriesInitialized;
});

// Mock repositories that return empty data during initialization
dynamic _createMockSeasonRepository() {
  return MockRepository('Season', []);
}

dynamic _createMockTeamRepository() {
  return MockRepository('Team', []);
}

dynamic _createMockPlayerRepository() {
  return MockRepository('Player', []);
}

// Simple mock repository class that returns empty results
class MockRepository {
  final String type;
  final List data;

  MockRepository(this.type, this.data);

  // Common repository methods that return empty results
  List getSeasons() => [];
  List getTeams() => [];
  List getPlayers() => [];
  List getTeamsForSeason(String seasonId) => [];
  List getPlayersForTeam(String teamId) => [];
  dynamic getSeason(String id) => null;
  dynamic getTeam(String id) => null;
  dynamic getPlayer(String id) => null;

  // Additional common methods that might be called
  List getTrainings() => [];
  List getMatches() => [];
  List getNotes() => [];
  bool isOnboardingCompleted = false;

  // Safely handle all other method calls
  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (kDebugMode) {
      print('🔧 MockRepository($type): Called ${invocation.memberName} - returning empty/null');
    }
    // Return appropriate empty values for common return types
    return null;
  }
}

// Sync-aware repository providers that switch between local and sync repositories
// Returns SeasonRepository or SeasonSyncRepository (both have same interface)
final seasonRepositoryProvider = Provider<dynamic>((ref) {
  final authState = ref.watch(firebaseAuthProvider);
  final initialized = ref.watch(repositoriesInitializedProvider);

  // If user is authenticated with Firebase and SyncManager is initialized, use sync repository
  if (authState.isUsingFirebaseAuth &&
      !authState.isInitializing &&
      SyncManager.instance.isInitialized) {
    return SyncManager.instance.seasonRepository;
  }

  // Fallback to base repository if initialized (better than mock during onboarding)
  if (initialized && _seasonRepository != null) {
    return _seasonRepository!;
  }

  // Return a safe fallback instead of throwing an error during initialization
  return _createMockSeasonRepository();
});

// Returns TeamRepository or TeamSyncRepository (both have same interface)
final teamRepositoryProvider = Provider<dynamic>((ref) {
  final authState = ref.watch(firebaseAuthProvider);
  final initialized = ref.watch(repositoriesInitializedProvider);

  // For Firebase users, prefer sync repository if available
  if (authState.isUsingFirebaseAuth &&
      !authState.isInitializing &&
      SyncManager.instance.isInitialized) {
    return SyncManager.instance.teamRepository;
  }

  // Fallback to base repository if initialized (better than mock during onboarding)
  if (initialized && _teamRepository != null) {
    return _teamRepository!;
  }

  // Only use mock as last resort
  return _createMockTeamRepository();
});

// Returns PlayerRepository or PlayerSyncRepository (both have same interface)
final playerRepositoryProvider = Provider<dynamic>((ref) {
  final authState = ref.watch(firebaseAuthProvider);
  final initialized = ref.watch(repositoriesInitializedProvider);

  if (authState.isUsingFirebaseAuth &&
      !authState.isInitializing &&
      SyncManager.instance.isInitialized) {
    return SyncManager.instance.playerRepository;
  }

  if (!initialized || _playerRepository == null) {
    return _createMockPlayerRepository();
  }
  return _playerRepository!;
});

// Additional providers for forced refresh
final playerListProvider = Provider<List<Player>>((ref) {
  final repo = ref.watch(playerRepositoryProvider);
  return repo.getPlayers();
});
// Returns TrainingRepository or TrainingSyncRepository (both have same interface)
final trainingRepositoryProvider = Provider<dynamic>((ref) {
  final authState = ref.watch(firebaseAuthProvider);
  final initialized = ref.watch(repositoriesInitializedProvider);

  if (authState.isUsingFirebaseAuth &&
      !authState.isInitializing &&
      SyncManager.instance.isInitialized) {
    return SyncManager.instance.trainingRepository;
  }

  if (!initialized || _trainingRepository == null) {
    return MockRepository('Training', []);
  }
  return _trainingRepository!;
});

final trainingAttendanceRepositoryProvider = Provider<dynamic>((ref) {
  final authState = ref.watch(firebaseAuthProvider);
  final initialized = ref.watch(repositoriesInitializedProvider);

  if (authState.isUsingFirebaseAuth &&
      !authState.isInitializing &&
      SyncManager.instance.isInitialized) {
    return SyncManager.instance.trainingAttendanceRepository;
  }

  if (!initialized || _trainingAttendanceRepository == null) {
    return MockRepository('TrainingAttendance', []);
  }
  return _trainingAttendanceRepository!;
});

// Returns MatchRepository or MatchSyncRepository (both have same interface)
final matchRepositoryProvider = Provider<dynamic>((ref) {
  final authState = ref.watch(firebaseAuthProvider);
  final initialized = ref.watch(repositoriesInitializedProvider);

  if (authState.isUsingFirebaseAuth &&
      !authState.isInitializing &&
      SyncManager.instance.isInitialized) {
    return SyncManager.instance.matchRepository;
  }

  if (!initialized || _matchRepository == null) {
    return MockRepository('Match', []);
  }
  return _matchRepository!;
});

final matchConvocationRepositoryProvider = Provider<dynamic>((ref) {
  final authState = ref.watch(firebaseAuthProvider);
  final initialized = ref.watch(repositoriesInitializedProvider);

  if (authState.isUsingFirebaseAuth &&
      !authState.isInitializing &&
      SyncManager.instance.isInitialized) {
    return SyncManager.instance.matchConvocationRepository;
  }

  if (!initialized || _matchConvocationRepository == null) {
    return MockRepository('MatchConvocation', []);
  }
  return _matchConvocationRepository!;
});

final matchStatisticRepositoryProvider = Provider<dynamic>((ref) {
  final authState = ref.watch(firebaseAuthProvider);
  final initialized = ref.watch(repositoriesInitializedProvider);

  if (authState.isUsingFirebaseAuth &&
      !authState.isInitializing &&
      SyncManager.instance.isInitialized) {
    return SyncManager.instance.matchStatisticRepository;
  }

  if (!initialized || _matchStatisticRepository == null) {
    return MockRepository('MatchStatistic', []);
  }
  return _matchStatisticRepository!;
});

final onboardingRepositoryProvider = Provider<dynamic>((ref) {
  final initialized = ref.watch(repositoriesInitializedProvider);

  if (!initialized || _onboardingRepository == null) {
    return MockRepository('Onboarding', []);
  }
  return _onboardingRepository!;
});

final userRepositoryProvider = Provider<dynamic>((ref) {
  final initialized = ref.watch(repositoriesInitializedProvider);

  if (!initialized || _userRepository == null) {
    return MockRepository('User', []);
  }
  return _userRepository!;
});

// Returns NoteRepository or NoteSyncRepository (both have same interface)
final noteRepositoryProvider = Provider<dynamic>((ref) {
  final authState = ref.watch(firebaseAuthProvider);
  final initialized = ref.watch(repositoriesInitializedProvider);

  if (authState.isUsingFirebaseAuth &&
      !authState.isInitializing &&
      SyncManager.instance.isInitialized) {
    return SyncManager.instance.noteRepository;
  }

  if (!initialized || _noteRepository == null) {
    return MockRepository('Note', []);
  }
  return _noteRepository!;
});

// Removed - onboarding status provider is now in app_initialization.dart

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
