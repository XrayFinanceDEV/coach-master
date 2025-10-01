import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:coachmaster/models/user.dart';
import 'package:coachmaster/models/auth_state.dart';
import 'package:coachmaster/services/firebase_auth_service.dart';
import 'package:coachmaster/models/season.dart';
import 'package:coachmaster/models/team.dart';
import 'package:coachmaster/core/repository_instances.dart';

// Firebase Auth Service Provider - singleton instance
final firebaseAuthServiceProvider = Provider<FirebaseAuthService>((ref) {
  return FirebaseAuthService();
});

// Enhanced Auth State Notifier with Firebase
class AuthNotifier extends Notifier<AuthState> {
  late final FirebaseAuthService _firebaseAuthService;

  @override
  AuthState build() {
    _firebaseAuthService = ref.watch(firebaseAuthServiceProvider);
    _checkAuthStatus();
    return const AuthState.initial();
  }

  Future<void> _checkAuthStatus() async {
    state = const AuthState.loading();

    if (kDebugMode) {
      print('🔥 AuthNotifier: Checking Firebase authentication status');
    }

    try {
      await _initializeFirebaseAuth();
    } catch (e) {
      if (kDebugMode) {
        print('🔴 AuthNotifier: Auth initialization error - $e');
      }
      state = AuthState.unauthenticated('Failed to check auth status: $e');
    }
  }

  Future<void> _initializeFirebaseAuth() async {
    if (kDebugMode) {
      print('🔥 AuthNotifier: Initializing Firebase authentication');
    }

    // Set up Firebase auth state listener
    _firebaseAuthService.authStateChanges().listen((firebaseUser) {
      if (firebaseUser != null) {
        if (kDebugMode) {
          print('🔥 AuthNotifier: Firebase user authenticated - ${firebaseUser.email}');
        }
        state = AuthState.firebaseAuthenticated(firebaseUser);
      } else {
        if (kDebugMode) {
          print('🔥 AuthNotifier: No Firebase user found');
        }
        state = const AuthState.unauthenticated();
      }
    });

    // Check current Firebase auth state
    final currentFirebaseUser = _firebaseAuthService.getCurrentUser();
    if (currentFirebaseUser != null) {
      state = AuthState.firebaseAuthenticated(currentFirebaseUser);
    } else {
      state = const AuthState.unauthenticated();
    }
  }

  // Login with Firebase
  Future<void> login({required String email, required String password}) async {
    state = const AuthState.loading();

    if (kDebugMode) {
      print('🔥 AuthNotifier: Logging in with Firebase');
    }

    try {
      await _firebaseAuthService.signInWithEmail(email, password);
      // State will be updated by the auth stream listener
    } catch (e) {
      if (kDebugMode) {
        print('🔴 AuthNotifier: Firebase login error - $e');
      }
      state = AuthState.unauthenticated(e.toString());
      rethrow;
    }
  }

  // Register with Firebase
  Future<void> register({required String name, required String email, required String password}) async {
    state = const AuthState.loading();

    if (kDebugMode) {
      print('🔥 AuthNotifier: Registering with Firebase');
    }

    try {
      await _firebaseAuthService.registerWithEmail(email, password, name);
      // State will be updated by the auth stream listener
    } catch (e) {
      if (kDebugMode) {
        print('🔴 AuthNotifier: Firebase registration error - $e');
      }
      state = AuthState.unauthenticated(e.toString());
      rethrow;
    }
  }

  // Google Sign-In
  Future<void> signInWithGoogle() async {
    state = const AuthState.loading();

    if (kDebugMode) {
      print('🔥 AuthNotifier: Signing in with Google');
    }

    try {
      final userCredential = await _firebaseAuthService.signInWithGoogle();
      if (userCredential == null) {
        // User cancelled the sign-in
        state = const AuthState.unauthenticated();
        return;
      }
      // State will be updated by the auth stream listener
    } catch (e) {
      if (kDebugMode) {
        print('🔴 AuthNotifier: Google Sign-In error - $e');
      }
      state = AuthState.unauthenticated(e.toString());
      rethrow;
    }
  }

  // Logout
  Future<void> logout() async {
    state = const AuthState.loading();

    if (kDebugMode) {
      print('🔥 AuthNotifier: Logging out from Firebase');
    }

    try {
      await _firebaseAuthService.signOut();

      if (kDebugMode) {
        print('🔥 AuthNotifier: Firebase logout successful');
      }

      state = const AuthState.unauthenticated();

    } catch (e) {
      if (kDebugMode) {
        print('🔴 AuthNotifier: Logout error - $e');
      }
      // Force state to unauthenticated even if logout fails
      state = const AuthState.unauthenticated();
    }
  }
}

final authNotifierProvider = NotifierProvider<AuthNotifier, AuthState>(
  () => AuthNotifier(),
);

// Onboarding State Notifier (Firebase-based)
class OnboardingNotifier extends Notifier<OnboardingState> {
  @override
  OnboardingState build() {
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
      // Register the user with Firebase
      await ref.read(authNotifierProvider.notifier).register(
        name: state.name!,
        email: state.email!,
        password: state.password!,
      );

      if (kDebugMode) {
        print('🟢 OnboardingNotifier: User registered with Firebase');
      }

      // Create season using Firestore repository
      try {
        final seasonRepo = ref.read(seasonRepositoryProvider);
        final season = Season.create(name: seasonName);
        await seasonRepo.addSeason(season);

        if (kDebugMode) {
          print('🟢 OnboardingNotifier: Season created');
        }

        // Create team
        final teamRepo = ref.read(teamRepositoryProvider);
        final team = Team.create(name: teamName, seasonId: season.id);
        await teamRepo.addTeam(team);

        if (kDebugMode) {
          print('🟢 OnboardingNotifier: Team created');
        }
      } catch (e) {
        if (kDebugMode) {
          print('🔴 OnboardingNotifier: Failed to create season/team - $e');
        }
        rethrow;
      }

      // Increment refresh counter to trigger UI rebuilds across the app
      ref.read(refreshCounterProvider.notifier).state++;

      if (kDebugMode) {
        print('🟢 OnboardingNotifier: Onboarding completed successfully');
      }

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
  // For Firebase users, consider onboarding completed if authenticated
  return authState.isUsingFirebaseAuth;
});

final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authNotifierProvider);
  return authState.user;
});

// Firebase users provider
final currentFirebaseUserProvider = Provider<firebase_auth.User?>((ref) {
  final authState = ref.watch(authNotifierProvider);
  return authState.firebaseUser;
});
