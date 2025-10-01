import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coachmaster/services/firestore_player_repository.dart';
import 'package:coachmaster/services/firestore_season_repository.dart';
import 'package:coachmaster/services/firestore_team_repository.dart';
import 'package:coachmaster/services/firestore_training_repository.dart';
import 'package:coachmaster/services/firestore_training_attendance_repository.dart';
import 'package:coachmaster/services/firestore_match_repository.dart';
import 'package:coachmaster/services/firestore_match_convocation_repository.dart';
import 'package:coachmaster/services/firestore_match_statistic_repository.dart';
import 'package:coachmaster/services/firestore_note_repository.dart';
import 'package:coachmaster/services/firestore_user_settings_repository.dart';
import 'package:coachmaster/models/player.dart';
import 'package:coachmaster/models/season.dart';
import 'package:coachmaster/models/team.dart';
import 'package:coachmaster/models/training.dart';
import 'package:coachmaster/models/training_attendance.dart';
import 'package:coachmaster/models/match.dart';
import 'package:coachmaster/models/match_convocation.dart';
import 'package:coachmaster/models/match_statistic.dart';
import 'package:coachmaster/models/note.dart';
import 'package:coachmaster/core/firebase_auth_providers.dart';

// ============================================================================
// Firestore-Only Repository Providers
// Single source of truth: Firestore with offline caching
// No Hive, no sync complexity, real-time updates via streams
// ============================================================================

/// Season Repository Provider
final seasonRepositoryProvider = Provider<FirestoreSeasonRepository>((ref) {
  final authState = ref.watch(firebaseAuthProvider);

  if (!authState.isAuthenticated || authState.firebaseUser == null) {
    throw Exception('User must be authenticated to access repositories');
  }

  return FirestoreSeasonRepository(userId: authState.firebaseUser!.uid);
});

/// Team Repository Provider
final teamRepositoryProvider = Provider<FirestoreTeamRepository>((ref) {
  final authState = ref.watch(firebaseAuthProvider);

  if (!authState.isAuthenticated || authState.firebaseUser == null) {
    throw Exception('User must be authenticated to access repositories');
  }

  return FirestoreTeamRepository(userId: authState.firebaseUser!.uid);
});

/// Player Repository Provider
final playerRepositoryProvider = Provider<FirestorePlayerRepository>((ref) {
  final authState = ref.watch(firebaseAuthProvider);

  if (!authState.isAuthenticated || authState.firebaseUser == null) {
    throw Exception('User must be authenticated to access repositories');
  }

  return FirestorePlayerRepository(userId: authState.firebaseUser!.uid);
});

/// Training Repository Provider
final trainingRepositoryProvider = Provider<FirestoreTrainingRepository>((ref) {
  final authState = ref.watch(firebaseAuthProvider);

  if (!authState.isAuthenticated || authState.firebaseUser == null) {
    throw Exception('User must be authenticated to access repositories');
  }

  return FirestoreTrainingRepository(userId: authState.firebaseUser!.uid);
});

/// Training Attendance Repository Provider
final trainingAttendanceRepositoryProvider = Provider<FirestoreTrainingAttendanceRepository>((ref) {
  final authState = ref.watch(firebaseAuthProvider);

  if (!authState.isAuthenticated || authState.firebaseUser == null) {
    throw Exception('User must be authenticated to access repositories');
  }

  return FirestoreTrainingAttendanceRepository(userId: authState.firebaseUser!.uid);
});

/// Match Repository Provider
final matchRepositoryProvider = Provider<FirestoreMatchRepository>((ref) {
  final authState = ref.watch(firebaseAuthProvider);

  if (!authState.isAuthenticated || authState.firebaseUser == null) {
    throw Exception('User must be authenticated to access repositories');
  }

  return FirestoreMatchRepository(userId: authState.firebaseUser!.uid);
});

/// Match Convocation Repository Provider
final matchConvocationRepositoryProvider = Provider<FirestoreMatchConvocationRepository>((ref) {
  final authState = ref.watch(firebaseAuthProvider);

  if (!authState.isAuthenticated || authState.firebaseUser == null) {
    throw Exception('User must be authenticated to access repositories');
  }

  return FirestoreMatchConvocationRepository(userId: authState.firebaseUser!.uid);
});

/// Match Statistic Repository Provider
final matchStatisticRepositoryProvider = Provider<FirestoreMatchStatisticRepository>((ref) {
  final authState = ref.watch(firebaseAuthProvider);

  if (!authState.isAuthenticated || authState.firebaseUser == null) {
    throw Exception('User must be authenticated to access repositories');
  }

  return FirestoreMatchStatisticRepository(userId: authState.firebaseUser!.uid);
});

/// Note Repository Provider
final noteRepositoryProvider = Provider<FirestoreNoteRepository>((ref) {
  final authState = ref.watch(firebaseAuthProvider);

  if (!authState.isAuthenticated || authState.firebaseUser == null) {
    throw Exception('User must be authenticated to access repositories');
  }

  return FirestoreNoteRepository(userId: authState.firebaseUser!.uid);
});

/// User Settings Repository Provider
final userSettingsRepositoryProvider = Provider<FirestoreUserSettingsRepository>((ref) {
  final authState = ref.watch(firebaseAuthProvider);

  if (!authState.isAuthenticated || authState.firebaseUser == null) {
    throw Exception('User must be authenticated to access repositories');
  }

  return FirestoreUserSettingsRepository(userId: authState.firebaseUser!.uid);
});

// ============================================================================
// Real-time Stream Providers - Auto-updating data from Firestore
// ============================================================================

/// Stream of all seasons (real-time updates)
final seasonsStreamProvider = StreamProvider<List<Season>>((ref) {
  final repo = ref.watch(seasonRepositoryProvider);
  return repo.seasonsStream();
});

/// Stream of a single season (real-time updates)
final seasonStreamProvider = StreamProvider.family<Season?, String>((ref, seasonId) {
  final repo = ref.watch(seasonRepositoryProvider);
  return repo.seasonStream(seasonId);
});

/// Stream of all teams (real-time updates)
final teamsStreamProvider = StreamProvider<List<Team>>((ref) {
  final repo = ref.watch(teamRepositoryProvider);
  return repo.teamsStream();
});

/// Stream of a single team (real-time updates)
final teamStreamProvider = StreamProvider.family<Team?, String>((ref, teamId) {
  final repo = ref.watch(teamRepositoryProvider);
  return repo.teamStream(teamId);
});

/// Stream of teams for a specific season (real-time updates)
final teamsForSeasonStreamProvider = StreamProvider.family<List<Team>, String>((ref, seasonId) {
  final repo = ref.watch(teamRepositoryProvider);
  return repo.teamsForSeasonStream(seasonId);
});

/// Stream of all players (real-time updates)
final playersStreamProvider = StreamProvider<List<Player>>((ref) {
  final repo = ref.watch(playerRepositoryProvider);
  return repo.playersStream();
});

/// Stream of players for a specific team (real-time updates)
final playersForTeamStreamProvider = StreamProvider.family<List<Player>, String>((ref, teamId) {
  final repo = ref.watch(playerRepositoryProvider);
  return repo.playersForTeamStream(teamId);
});

/// Stream of a single player (real-time updates)
final playerStreamProvider = StreamProvider.family<Player?, String>((ref, playerId) {
  final repo = ref.watch(playerRepositoryProvider);
  return repo.playerStream(playerId);
});

/// Stream of all trainings (real-time updates)
final trainingsStreamProvider = StreamProvider<List<Training>>((ref) {
  final repo = ref.watch(trainingRepositoryProvider);
  return repo.trainingsStream();
});

/// Stream of trainings for a specific team (real-time updates)
final trainingsForTeamStreamProvider = StreamProvider.family<List<Training>, String>((ref, teamId) {
  final repo = ref.watch(trainingRepositoryProvider);
  return repo.trainingsForTeamStream(teamId);
});

/// Stream of a single training (real-time updates)
final trainingStreamProvider = StreamProvider.family<Training?, String>((ref, trainingId) {
  final repo = ref.watch(trainingRepositoryProvider);
  return repo.trainingStream(trainingId);
});

/// Stream of all training attendances (real-time updates)
final attendancesStreamProvider = StreamProvider<List<TrainingAttendance>>((ref) {
  final repo = ref.watch(trainingAttendanceRepositoryProvider);
  return repo.attendancesStream();
});

/// Stream of attendances for a specific training (real-time updates)
final attendancesForTrainingStreamProvider = StreamProvider.family<List<TrainingAttendance>, String>((ref, trainingId) {
  final repo = ref.watch(trainingAttendanceRepositoryProvider);
  return repo.attendancesForTrainingStream(trainingId);
});

/// Stream of all matches (real-time updates)
final matchesStreamProvider = StreamProvider<List<Match>>((ref) {
  final repo = ref.watch(matchRepositoryProvider);
  return repo.matchesStream();
});

/// Stream of matches for a specific team (real-time updates)
final matchesForTeamStreamProvider = StreamProvider.family<List<Match>, String>((ref, teamId) {
  final repo = ref.watch(matchRepositoryProvider);
  return repo.matchesForTeamStream(teamId);
});

/// Stream of a single match (real-time updates)
final matchStreamProvider = StreamProvider.family<Match?, String>((ref, matchId) {
  final repo = ref.watch(matchRepositoryProvider);
  return repo.matchStream(matchId);
});

/// Stream of convocations for a specific match (real-time updates)
final convocationsForMatchStreamProvider = StreamProvider.family<List<MatchConvocation>, String>((ref, matchId) {
  final repo = ref.watch(matchConvocationRepositoryProvider);
  return repo.convocationsForMatchStream(matchId);
});

/// Stream of statistics for a specific match (real-time updates)
final statisticsForMatchStreamProvider = StreamProvider.family<List<MatchStatistic>, String>((ref, matchId) {
  final repo = ref.watch(matchStatisticRepositoryProvider);
  return repo.statisticsForMatchStream(matchId);
});

/// Stream of a single match statistic (real-time updates)
final statisticStreamProvider = StreamProvider.family<MatchStatistic?, String>((ref, statisticId) {
  final repo = ref.watch(matchStatisticRepositoryProvider);
  return repo.statisticStream(statisticId);
});

/// Stream of notes for a specific player (real-time updates)
final notesForPlayerStreamProvider = StreamProvider.family<List<Note>, String>((ref, playerId) {
  final repo = ref.watch(noteRepositoryProvider);
  return repo.notesForPlayerStream(playerId);
});

/// Stream of notes for a specific training (real-time updates)
final notesForTrainingStreamProvider = StreamProvider.family<List<Note>, String>((ref, trainingId) {
  final repo = ref.watch(noteRepositoryProvider);
  return repo.notesForTrainingStream(trainingId);
});

/// Stream of notes for a specific match (real-time updates)
final notesForMatchStreamProvider = StreamProvider.family<List<Note>, String>((ref, matchId) {
  final repo = ref.watch(noteRepositoryProvider);
  return repo.notesForMatchStream(matchId);
});

// ============================================================================
// Legacy Compatibility - Simple counter for manual refresh triggers
// ============================================================================

class RefreshCounterNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void increment() {
    state++;
    if (kDebugMode) {
      print('🔄 Refresh counter incremented to $state');
    }
  }
}

final refreshCounterProvider = NotifierProvider<RefreshCounterNotifier, int>(() {
  return RefreshCounterNotifier();
});

// ============================================================================
// Backward Compatibility Helpers
// These provide synchronous access for legacy code that hasn't migrated to streams
// ============================================================================

/// Get players synchronously (for legacy code)
/// Prefer using playersForTeamStreamProvider for real-time updates
final playersForTeamProvider = Provider.family<AsyncValue<List<Player>>, String>((ref, teamId) {
  return ref.watch(playersForTeamStreamProvider(teamId));
});
