import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coachmaster/core/firestore_repository_providers.dart';
import 'package:coachmaster/core/firebase_auth_providers.dart';

/// Provider that manages app initialization state
/// With Firestore-only architecture, no Hive initialization needed
final appInitializationProvider = FutureProvider<void>((ref) async {
  if (kDebugMode) {
    print('🔥 App initialization: Firestore-only mode (no Hive)');
  }

  // Wait for Firebase auth to be ready
  final authState = ref.watch(firebaseAuthProvider);

  if (authState.isInitializing) {
    if (kDebugMode) {
      print('🔥 App initialization: Waiting for Firebase auth...');
    }
    // Will retry when auth state changes
    throw Exception('Firebase auth still initializing');
  }

  if (kDebugMode) {
    print('🟢 App initialization: Complete');
  }
});

/// Provider to check if app is ready
final appReadyProvider = Provider<bool>((ref) {
  final initialization = ref.watch(appInitializationProvider);
  final authState = ref.watch(firebaseAuthProvider);

  return initialization.when(
    data: (_) => !authState.isInitializing,
    loading: () => false,
    error: (_, __) => !authState.isInitializing, // Allow app to run even if init fails
  );
});

/// Provider to check if user has completed setup by checking if they have teams
final onboardingStatusProvider = FutureProvider<bool>((ref) async {
  // Ensure app is ready before checking
  final appReady = ref.watch(appReadyProvider);
  if (!appReady) {
    if (kDebugMode) {
      print('🎯 OnboardingStatus: App not ready, returning false');
    }
    return false;
  }

  final authState = ref.watch(firebaseAuthProvider);

  // If not authenticated, show onboarding
  if (!authState.isAuthenticated) {
    if (kDebugMode) {
      print('🎯 OnboardingStatus: Not authenticated, returning false');
    }
    return false;
  }

  // Wait a moment to ensure auth is fully initialized
  if (authState.isInitializing) {
    if (kDebugMode) {
      print('🎯 OnboardingStatus: Auth still initializing, returning false');
    }
    return false;
  }

  try {
    // Give Firestore a moment to check its offline cache before querying
    // This prevents false negatives when users have existing data
    await Future.delayed(const Duration(milliseconds: 500));

    // Check if user has any teams (async Firestore call)
    final teamRepo = ref.watch(teamRepositoryProvider);
    final allTeams = await teamRepo.getTeams();

    if (kDebugMode) {
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
  } catch (e) {
    if (kDebugMode) {
      print('🔴 OnboardingStatus: Error checking teams - $e');
    }
    // On error, assume onboarding not complete
    return false;
  }
});
