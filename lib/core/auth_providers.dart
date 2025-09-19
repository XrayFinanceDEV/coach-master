import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:coachmaster/models/user.dart';
import 'package:coachmaster/models/auth_state.dart';
import 'package:coachmaster/services/auth_service.dart';
import 'package:coachmaster/services/firebase_auth_service.dart';
import 'package:coachmaster/services/sync_manager.dart';
import 'package:coachmaster/models/season.dart';
import 'package:coachmaster/models/team.dart';
import 'package:coachmaster/core/repository_instances.dart';

// Firebase Auth Service Provider - singleton instance
final firebaseAuthServiceProvider = Provider<FirebaseAuthService>((ref) {
  return FirebaseAuthService();
});

// Legacy Auth Service Provider - singleton instance (maintained for backward compatibility)
final authServiceProvider = Provider<AuthService>((ref) {
  final authService = AuthService();
  // Don't initialize here - it will be initialized properly in AuthNotifier
  return authService;
});

// Enhanced Auth State Notifier with Firebase Integration
class AuthNotifier extends Notifier<AuthState> {
  late final AuthService _authService;
  late final FirebaseAuthService _firebaseAuthService;
  
  // Flag to determine which auth system to use (Firebase-first approach)
  bool get _useFirebaseAuth => true; // Always try Firebase first

  @override
  AuthState build() {
    _authService = ref.watch(authServiceProvider);
    _firebaseAuthService = ref.watch(firebaseAuthServiceProvider);
    _checkAuthStatus(); // Call initial setup
    return const AuthState.initial(); // Initial state
  }

  // Note: Riverpod 3.0 Notifier doesn't have a dispose method
  // StreamSubscription will be cancelled when the provider is disposed

  Future<void> _checkAuthStatus() async {
    state = const AuthState.loading();
    
    if (kDebugMode) {
      print('🟢 AuthNotifier: Checking authentication status (Firebase-first)');
    }
    
    try {
      if (_useFirebaseAuth) {
        // Try Firebase authentication first
        await _initializeFirebaseAuth();
      } else {
        // Fallback to local auth
        await _initializeLocalAuth();
      }
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
        
        // Initialize sync manager for the authenticated user
        SyncManager.instance.initializeForUser(firebaseUser).catchError((error) {
          if (kDebugMode) {
            print('🔴 AuthNotifier: Failed to initialize sync manager - $error');
          }
        });
      } else {
        if (kDebugMode) {
          print('🔥 AuthNotifier: No Firebase user found');
        }
        state = const AuthState.unauthenticated();
        
        // Clean up sync manager
        SyncManager.instance.cleanup().catchError((error) {
          if (kDebugMode) {
            print('🔴 AuthNotifier: Failed to cleanup sync manager - $error');
          }
        });
      }
    });
    
    // Check current Firebase auth state
    final currentFirebaseUser = _firebaseAuthService.getCurrentUser();
    if (currentFirebaseUser != null) {
      state = AuthState.firebaseAuthenticated(currentFirebaseUser);
      
      // Initialize sync manager for existing user
      SyncManager.instance.initializeForUser(currentFirebaseUser).catchError((error) {
        if (kDebugMode) {
          print('🔴 AuthNotifier: Failed to initialize sync manager for existing user - $error');
        }
      });
    } else {
      // No Firebase user, check if we have local user to migrate
      await _checkForLocalUserMigration();
    }
  }
  
  Future<void> _initializeLocalAuth() async {
    if (kDebugMode) {
      print('🔵 AuthNotifier: Initializing local authentication');
    }
    
    await _authService.init();
    final currentUser = await _authService.getCurrentUser();
    if (currentUser != null) {
      state = AuthState.authenticated(currentUser);
    } else {
      state = const AuthState.unauthenticated();
    }
  }
  
  Future<void> _checkForLocalUserMigration() async {
    // Check if we have a local user that could be migrated
    try {
      await _authService.init();
      final localUser = await _authService.getCurrentUser();
      if (localUser != null) {
        if (kDebugMode) {
          print('🟡 AuthNotifier: Found local user, but using Firebase auth now');
        }
        // For now, just show unauthenticated - user needs to log in with Firebase
      }
      state = const AuthState.unauthenticated();
    } catch (e) {
      if (kDebugMode) {
        print('🔴 AuthNotifier: Error checking local user - $e');
      }
      state = const AuthState.unauthenticated();
    }
  }

  // Updated login method to use Firebase
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
  
  // New registration method for Firebase
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
  
  // Google Sign-In method
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

  Future<void> logout() async {
    state = const AuthState.loading();
    
    if (kDebugMode) {
      print('🔥 AuthNotifier: Logging out from Firebase');
    }
    
    try {
      // Always try Firebase logout first since we're Firebase-first now
      await _firebaseAuthService.signOut();
      
      // Skip sync manager cleanup for now to avoid _sessionBox error
      // The cleanup will happen automatically when auth state changes
      
      if (kDebugMode) {
        print('🔥 AuthNotifier: Firebase logout successful');
      }
      
      // Force state change immediately to trigger navigation
      state = const AuthState.unauthenticated();
      
    } catch (e) {
      if (kDebugMode) {
        print('🔴 AuthNotifier: Logout error - $e');
      }
      // Force state to unauthenticated even if logout fails
      state = const AuthState.unauthenticated();
    }
  }

  // Legacy method maintained for backward compatibility
  Future<void> updateUser(User user) async {
    try {
      if (state.isUsingLocalAuth) {
        await _authService.updateUser(user);
        state = AuthState.authenticated(user);
      } else {
        // For Firebase users, this would need to update Firestore user document
        // For now, just maintain the current Firebase user state
        if (kDebugMode) {
          print('🟡 AuthNotifier: updateUser called for Firebase user - implement Firestore update in Phase 4');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('🔴 AuthNotifier: Update user error - $e');
      }
      state = AuthState.unauthenticated('Failed to update user: $e');
    }
  }
}

final authNotifierProvider = NotifierProvider<AuthNotifier, AuthState>(
  () => AuthNotifier(),
);

// Onboarding State Notifier (Updated for Firebase)
class OnboardingNotifier extends Notifier<OnboardingState> {
  // Use the main auth notifier for registration (which now uses Firebase)
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

      // Create season using sync-enabled repository if available
      try {
        final syncManager = SyncManager.instance;
        if (syncManager.isInitialized) {
          final season = Season.create(name: seasonName);
          await syncManager.seasonRepository.addSeason(season);
          
          if (kDebugMode) {
            print('🟢 OnboardingNotifier: Season created with sync support');
          }
        } else {
          // Fallback to regular repository
          final seasonRepo = ref.read(seasonRepositoryProvider);
          final season = Season.create(name: seasonName);
          await seasonRepo.addSeason(season);
          
          if (kDebugMode) {
            print('🟡 OnboardingNotifier: Season created without sync (fallback)');
          }
        }
      } catch (e) {
        if (kDebugMode) {
          print('🔴 OnboardingNotifier: Failed to create season - $e');
        }
        rethrow;
      }

      // Create team using sync-enabled repository if available  
      try {
        final syncManager = SyncManager.instance;
        if (syncManager.isInitialized) {
          // Get the created season ID (we'll need to fix this properly)
          final seasons = syncManager.seasonRepository.getSeasons();
          final latestSeason = seasons.isNotEmpty ? seasons.last : null;
          
          if (latestSeason != null) {
            final team = Team.create(name: teamName, seasonId: latestSeason.id);
            await syncManager.teamRepository.addTeam(team);
            
            if (kDebugMode) {
              print('🟢 OnboardingNotifier: Team created with sync support');
            }
          }
        } else {
          // Fallback to regular repository
          final teamRepo = ref.read(teamRepositoryProvider);
          final team = Team.create(name: teamName, seasonId: 'fallback-season-id');
          await teamRepo.addTeam(team);
          
          if (kDebugMode) {
            print('🟡 OnboardingNotifier: Team created without sync (fallback)');
          }
        }
      } catch (e) {
        if (kDebugMode) {
          print('🔴 OnboardingNotifier: Failed to create team - $e');
        }
        rethrow;
      }
      
      // Increment refresh counter to trigger UI rebuilds across the app
      ref.read(refreshCounterProvider.notifier).state++;

      if (kDebugMode) {
        print('🟢 OnboardingNotifier: Season and team created successfully');
      }

      // Note: For Firebase auth, user profile updates will be handled in Phase 4 (Firestore)
      // For now, the Firebase user is authenticated and the local season/team data is created
      
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
  // In Phase 4, this will be replaced with Firestore user document check
  if (authState.isUsingFirebaseAuth) {
    return true; // Firebase users are considered onboarded for now
  }
  return authState.user?.isOnboardingCompleted ?? false;
});

final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authNotifierProvider);
  // Return the local user if available (for backward compatibility)
  return authState.user;
});

// New provider for Firebase users
final currentFirebaseUserProvider = Provider<firebase_auth.User?>((ref) {
  final authState = ref.watch(authNotifierProvider);
  return authState.firebaseUser;
});