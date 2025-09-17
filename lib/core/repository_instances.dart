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
late final SeasonRepository _seasonRepository;
late final TeamRepository _teamRepository;
late final PlayerRepository _playerRepository;
late final TrainingRepository _trainingRepository;
late final TrainingAttendanceRepository _trainingAttendanceRepository;
late final MatchRepository _matchRepository;
late final BaseMatchConvocationRepository _matchConvocationRepository;
late final BaseMatchStatisticRepository _matchStatisticRepository;
late final OnboardingRepository _onboardingRepository;
late final UserRepository _userRepository;
late final NoteRepository _noteRepository;

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
      _seasonRepository.init(userId: userId),
      _teamRepository.init(userId: userId),
      _playerRepository.init(userId: userId),
      _trainingRepository.init(userId: userId),
      _trainingAttendanceRepository.init(), // TODO: Add userId support
      _matchRepository.init(), // TODO: Add userId support
      _matchConvocationRepository.init(), // TODO: Add userId support
      _matchStatisticRepository.init(), // TODO: Add userId support
      _onboardingRepository.init(), // Global, not user-specific
      _userRepository.init(), // Global, not user-specific
      _noteRepository.init(), // TODO: Add userId support
    ]);
  } catch (e) {
    // Handle initialization errors gracefully
    rethrow;
  }
}

/// Close all repositories (useful for user switching)
Future<void> closeRepositories() async {
  try {
    await Future.wait([
      _seasonRepository.close(),
      _teamRepository.close(),
      _playerRepository.close(),
      _trainingRepository.close(),
      // TODO: Add other repositories as we update them
    ]);
  } catch (e) {
    // Handle close errors gracefully
    print('Error closing repositories: $e');
  }
}

/// Provider for user-specific repository reinitialization
final repositoryReInitProvider = FutureProvider.family<void, String>((ref, userId) async {
  try {
    // Close existing repositories first
    await closeRepositories();
    
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

final trainingAttendanceRepositoryProvider = Provider<TrainingAttendanceRepository>((ref) => _trainingAttendanceRepository);

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
  
  return _matchConvocationRepository;
});

final matchStatisticRepositoryProvider = Provider<BaseMatchStatisticRepository>((ref) {
  final authState = ref.watch(firebaseAuthProvider);
  
  if (authState.isUsingFirebaseAuth && 
      !authState.isInitializing && 
      SyncManager.instance.isInitialized) {
    return SyncManager.instance.matchStatisticRepository;
  }
  
  return _matchStatisticRepository;
});

final onboardingRepositoryProvider = Provider<OnboardingRepository>((ref) => _onboardingRepository);
final userRepositoryProvider = Provider<UserRepository>((ref) => _userRepository);

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
