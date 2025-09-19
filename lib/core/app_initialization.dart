import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coachmaster/core/repository_instances.dart';

/// Provider that manages app initialization state
final appInitializationProvider = FutureProvider<void>((ref) async {
  // Initialize repositories in the background
  await initializeRepositories();
});

/// Provider to check if app is ready
final appReadyProvider = Provider<bool>((ref) {
  final initialization = ref.watch(appInitializationProvider);
  return initialization.when(
    data: (_) => true,
    loading: () => false,
    error: (_, __) => false,
  );
});

/// Provider to check if user has completed setup by checking if they have teams
final onboardingStatusProvider = Provider<bool>((ref) {
  // Ensure app is ready before checking
  final appReady = ref.watch(appReadyProvider);
  if (!appReady) {
    // Return false to show onboarding screen while initializing
    if (kDebugMode) {
      print('🎯 OnboardingStatus: App not ready, returning false');
    }
    return false;
  }

  // Simple approach: check if user has any teams
  // Firebase is the source of truth - if they have teams, they've completed onboarding
  final teamRepo = ref.watch(teamRepositoryProvider);
  final allTeams = teamRepo.getTeams();

  if (kDebugMode) {
    print('🎯 OnboardingStatus: Team repo type: ${teamRepo.runtimeType}');
    print('🎯 OnboardingStatus: Found ${allTeams.length} teams');
    for (final team in allTeams) {
      print('🎯 OnboardingStatus: Team: ${team.name} (ID: ${team.id})');
    }
  }

  // If user has teams, onboarding is complete
  final hasTeams = allTeams.isNotEmpty;
  if (kDebugMode) {
    print('🎯 OnboardingStatus: Returning hasTeams: $hasTeams');
  }
  return hasTeams;
});