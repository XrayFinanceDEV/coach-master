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

/// Provider to check onboarding status
final onboardingStatusProvider = Provider<bool>((ref) {
  // Ensure app is ready before checking onboarding status
  final appReady = ref.watch(appReadyProvider);
  if (!appReady) {
    // Return false to show onboarding screen while initializing
    return false;
  }
  
  final onboardingRepo = ref.watch(onboardingRepositoryProvider);
  return onboardingRepo.isOnboardingCompleted;
});