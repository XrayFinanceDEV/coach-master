import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coachmaster/services/season_repository.dart';
import 'package:coachmaster/services/team_repository.dart';
import 'package:coachmaster/services/player_repository.dart';
import 'package:coachmaster/services/training_repository.dart';
import 'package:coachmaster/services/training_attendance_repository.dart';
import 'package:coachmaster/services/match_repository.dart';
import 'package:coachmaster/services/match_convocation_repository.dart';
import 'package:coachmaster/services/match_statistic_repository.dart';
import 'package:coachmaster/services/onboarding_repository.dart';

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
final trainingRepositoryProvider = Provider((ref) => _trainingRepository);
final trainingAttendanceRepositoryProvider = Provider((ref) => _trainingAttendanceRepository);
final matchRepositoryProvider = Provider((ref) => _matchRepository);
final matchConvocationRepositoryProvider = Provider((ref) => _matchConvocationRepository);
final matchStatisticRepositoryProvider = Provider((ref) => _matchStatisticRepository);
final onboardingRepositoryProvider = Provider((ref) => _onboardingRepository);