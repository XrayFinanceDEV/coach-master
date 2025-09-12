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
import 'package:coachmaster/services/onboarding_repository.dart';
import 'package:coachmaster/services/user_repository.dart';
import 'package:coachmaster/services/note_repository.dart';

// Global repository instances
late final SeasonRepository _seasonRepository;
late final TeamRepository _teamRepository;
late final PlayerRepository _playerRepository;
late final TrainingRepository _trainingRepository;
late final TrainingAttendanceRepository _trainingAttendanceRepository;
late final MatchRepository _matchRepository;
late final MatchConvocationRepository _matchConvocationRepository;
late final MatchStatisticRepository _matchStatisticRepository;
late final OnboardingRepository _onboardingRepository;
late final UserRepository _userRepository;
late final NoteRepository _noteRepository;

/// Initialize all repositories efficiently in parallel
Future<void> initializeRepositories() async {
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
      _seasonRepository.init(),
      _teamRepository.init(),
      _playerRepository.init(),
      _trainingRepository.init(),
      _trainingAttendanceRepository.init(),
      _matchRepository.init(),
      _matchConvocationRepository.init(),
      _matchStatisticRepository.init(),
      _onboardingRepository.init(),
      _userRepository.init(),
      _noteRepository.init(),
    ]);
  } catch (e) {
    // Handle initialization errors gracefully
    rethrow;
  }
}

// Repository providers - centralized here to avoid circular imports
final seasonRepositoryProvider = Provider((ref) => _seasonRepository);
final teamRepositoryProvider = Provider((ref) => _teamRepository);
final playerRepositoryProvider = Provider((ref) => _playerRepository);

// Additional providers for forced refresh
final playerListProvider = Provider((ref) {
  final repo = ref.watch(playerRepositoryProvider);
  return repo.getPlayers();
});
final trainingRepositoryProvider = Provider((ref) => _trainingRepository);
final trainingAttendanceRepositoryProvider = Provider((ref) => _trainingAttendanceRepository);
final matchRepositoryProvider = Provider((ref) => _matchRepository);
final matchConvocationRepositoryProvider = Provider((ref) => _matchConvocationRepository);
final matchStatisticRepositoryProvider = Provider((ref) => _matchStatisticRepository);
final onboardingRepositoryProvider = Provider((ref) => _onboardingRepository);
final userRepositoryProvider = Provider((ref) => _userRepository);
final noteRepositoryProvider = Provider((ref) => _noteRepository);

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
