import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coachmaster/models/user.dart';
import 'package:coachmaster/models/auth_state.dart';
import 'package:coachmaster/services/auth_service.dart';
import 'package:coachmaster/models/season.dart';
import 'package:coachmaster/models/team.dart';
import 'package:coachmaster/core/repository_instances.dart';

// Auth Service Provider - singleton instance
final authServiceProvider = Provider<AuthService>((ref) {
  final authService = AuthService();
  // Don't initialize here - it will be initialized properly in AuthNotifier
  return authService;
});

// Auth State Notifier
class AuthNotifier extends Notifier<AuthState> {
  late final AuthService _authService;

  @override
  AuthState build() {
    _authService = ref.watch(authServiceProvider);
    _checkAuthStatus(); // Call initial setup
    return const AuthState.initial(); // Initial state
  }

  Future<void> _checkAuthStatus() async {
    state = const AuthState.loading();
    try {
      await _authService.init();
      final currentUser = await _authService.getCurrentUser();
      if (currentUser != null) {
        state = AuthState.authenticated(currentUser);
      } else {
        state = const AuthState.unauthenticated();
      }
    } catch (e) {
      state = AuthState.unauthenticated('Failed to check auth status: $e');
    }
  }

  Future<void> login({required String email, required String password}) async {
    state = const AuthState.loading();
    try {
      final user = await _authService.login(email: email, password: password);
      if (user != null) {
        state = AuthState.authenticated(user);
      } else {
        state = const AuthState.unauthenticated('Login failed');
      }
    } catch (e) {
      state = AuthState.unauthenticated(e.toString());
      rethrow;
    }
  }

  Future<void> logout() async {
    state = const AuthState.loading();
    try {
      await _authService.logout();
      state = const AuthState.unauthenticated();
    } catch (e) {
      state = AuthState.unauthenticated('Logout failed: $e');
    }
  }

  Future<void> updateUser(User user) async {
    try {
      await _authService.updateUser(user);
      state = AuthState.authenticated(user);
    } catch (e) {
      state = AuthState.unauthenticated('Failed to update user: $e');
    }
  }
}

final authNotifierProvider = NotifierProvider<AuthNotifier, AuthState>(
  () => AuthNotifier(),
);

// Onboarding State Notifier
class OnboardingNotifier extends Notifier<OnboardingState> {
  late final AuthService _authService;

  @override
  OnboardingState build() {
    _authService = ref.watch(authServiceProvider);
    return const OnboardingState.initial();
  }

  void updatePersonalInfo({required String name, required String email}) {
    state = state.copyWith(
      name: name,
      email: email,
      currentStep: OnboardingStep.password,
      errorMessage: null,
    );
  }

  void updatePassword({required String password, required String confirmPassword}) {
    if (password != confirmPassword) {
      state = state.copyWith(errorMessage: 'Passwords do not match');
      return;
    }
    
    state = state.copyWith(
      password: password,
      confirmPassword: confirmPassword,
      currentStep: OnboardingStep.teamSetup,
      errorMessage: null,
    );
  }

  void goToPreviousStep() {
    switch (state.currentStep) {
      case OnboardingStep.password:
        state = state.copyWith(currentStep: OnboardingStep.personalInfo);
        break;
      case OnboardingStep.teamSetup:
        state = state.copyWith(currentStep: OnboardingStep.password);
        break;
      case OnboardingStep.personalInfo:
      case OnboardingStep.completed:
        break;
    }
  }

  Future<void> completeOnboarding({
    required String seasonName,
    required String teamName,
  }) async {
    if (!state.canProceedFromPersonalInfo || !state.canProceedFromPassword) {
      state = state.copyWith(errorMessage: 'Please complete all required fields');
      return;
    }

    state = state.copyWith(
      isLoading: true,
      seasonName: seasonName,
      teamName: teamName,
      errorMessage: null,
    );

    try {
      // Register the user
      final user = await _authService.register(
        name: state.name!,
        email: state.email!,
        password: state.password!,
      );

      if (user == null) {
        throw Exception('User registration failed');
      }

      // Create season
      final seasonRepo = ref.read(seasonRepositoryProvider);
      final season = Season.create(name: seasonName);
      await seasonRepo.addSeason(season);

      // Create team
      final teamRepo = ref.read(teamRepositoryProvider);
      final team = Team.create(name: teamName, seasonId: season.id);
      await teamRepo.addTeam(team);
      
      // Increment refresh counter to trigger UI rebuilds across the app
      // This will be fixed in repository_instances.dart
      ref.read(refreshCounterProvider.notifier).increment(); // Assuming refreshCounterProvider is updated to NotifierProvider

      // Update user with current season and team
      final updatedUser = user.copyWith(
        currentSeasonId: season.id,
        currentTeamId: team.id,
        isOnboardingCompleted: true,
      );
      await _authService.updateUser(updatedUser);

      // Update auth state
      ref.read(authNotifierProvider.notifier).updateUser(updatedUser);

      state = state.copyWith(
        currentStep: OnboardingStep.completed,
        isLoading: false,
      );

    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      throw Exception(e.toString());
    }
  }

  void resetOnboarding() {
    state = const OnboardingState.initial();
  }
}

final onboardingNotifierProvider = NotifierProvider<OnboardingNotifier, OnboardingState>(
  () => OnboardingNotifier(),
);

// Helper providers for router
final isAuthenticatedProvider = Provider<bool>((ref) {
  final authState = ref.watch(authNotifierProvider);
  return authState.isAuthenticated;
});

final isOnboardingCompletedProvider = Provider<bool>((ref) {
  final authState = ref.watch(authNotifierProvider);
  return authState.user?.isOnboardingCompleted ?? false;
});

final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authNotifierProvider);
  return authState.user;
});