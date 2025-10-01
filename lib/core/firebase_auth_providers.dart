import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:coachmaster/services/firebase_auth_service.dart';
// Legacy sync_manager removed - using Firestore-only architecture now
import 'package:coachmaster/models/auth_state.dart';
import 'package:coachmaster/core/app_initialization.dart';
import 'package:coachmaster/core/selected_team_provider.dart';

class FirebaseAuthNotifier extends Notifier<AuthState> {
  FirebaseAuthService? _authService;
  
  @override
  AuthState build() {
    // Initialize the auth service
    _authService = ref.read(firebaseAuthServiceProvider);
    
    // Initialize auth state listener
    _initializeAuth();
    
    return const AuthState.initial();
  }
  
  void _initializeAuth() {
    if (kDebugMode) {
      print('🔥 FirebaseAuthNotifier: Initializing auth state listener');
    }
    
    _authService!.authStateChanges().listen((firebaseUser) {
      if (firebaseUser != null) {
        _handleUserSignedIn(firebaseUser);
      } else {
        _handleUserSignedOut();
      }
    });
  }
  
  Future<void> _handleUserSignedIn(User firebaseUser) async {
    if (kDebugMode) {
      print('🔥 FirebaseAuthNotifier: User signed in - ${firebaseUser.email}');
    }

    // 1. Set authenticated state with loading
    state = AuthState.firebaseAuthenticated(firebaseUser, isInitializing: true);

    // 2. Initialize user-specific data storage and ensure repositories are ready
    try {
      await _initializeUserData(firebaseUser.uid);

      // 3. Additional delay to ensure everything is settled
      await Future.delayed(const Duration(milliseconds: 1000));

      // 4. Only mark as ready after everything is completely initialized
      state = AuthState.firebaseAuthenticated(firebaseUser, isInitializing: false);

      if (kDebugMode) {
        print('🔥 FirebaseAuthNotifier: User initialization complete');
      }
    } catch (e) {
      if (kDebugMode) {
        print('🔥 FirebaseAuthNotifier: Initialization failed: $e');
      }
      // If initialization fails, stay in initializing state longer
      await Future.delayed(const Duration(seconds: 2));
      state = AuthState.firebaseAuthenticated(firebaseUser, isInitializing: false);
    }
  }
  
  Future<void> _handleUserSignedOut() async {
    if (kDebugMode) {
      print('🔥 FirebaseAuthNotifier: User signed out');
    }

    // 1. Clean up user-specific data
    await _cleanupUserData();

    // 2. Clear selected team/season to prevent data leakage between accounts
    try {
      await ref.read(selectedTeamIdProvider.notifier).clearTeam();
      if (kDebugMode) {
        print('🔥 FirebaseAuthNotifier: Cleared selected team');
      }
    } catch (e) {
      if (kDebugMode) {
        print('🔥 FirebaseAuthNotifier: Error clearing selected team - $e');
      }
    }

    // 3. Set unauthenticated state
    state = const AuthState.unauthenticated();
  }
  
  Future<void> _initializeUserData(String userId) async {
    if (kDebugMode) {
      print('🔥 FirebaseAuthNotifier: Initializing user data for $userId');
    }

    try {
      // Firebase/Firestore repositories are already initialized globally
      // No need for user-specific initialization anymore
      if (kDebugMode) {
        print('🔥 FirebaseAuthNotifier: Repositories are ready (Firestore-based)');
      }

      // Get Firebase user from auth service
      final firebaseUser = _authService?.currentUser;
      if (firebaseUser == null) {
        if (kDebugMode) {
          print('🔥 FirebaseAuthNotifier: Firebase user is null, continuing with local-only mode');
        }
        return; // Continue without sync
      }

      // SyncManager removed - Firestore handles sync automatically with offline persistence
      // No manual sync initialization needed

      if (kDebugMode) {
        print('🔥 FirebaseAuthNotifier: Firestore auto-sync enabled for user $userId');
      }

      // Invalidate onboarding status provider to force router to check teams
      ref.invalidate(onboardingStatusProvider);

      if (kDebugMode) {
        print('🔥 FirebaseAuthNotifier: Team data available, onboarding status refreshed');
      }

      // Firestore handles initial data sync automatically
      // Offline persistence ensures data is available even without network
      if (kDebugMode) {
        print('🔥 FirebaseAuthNotifier: Firestore managing data sync automatically for user $userId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('🔥 FirebaseAuthNotifier: Error initializing user data: $e');
      }
      // Don't rethrow - allow auth to continue with local-only mode
    }
  }


  Future<void> _cleanupUserData() async {
    if (kDebugMode) {
      print('🔥 FirebaseAuthNotifier: Cleaning up user data');
    }
    
    try {
      // SyncManager removed - Firestore handles cleanup automatically
      // No manual cleanup needed - streams and listeners are disposed automatically

      if (kDebugMode) {
        print('🔥 FirebaseAuthNotifier: Firestore streams cleaned up automatically');
      }
    } catch (e) {
      if (kDebugMode) {
        print('🔥 FirebaseAuthNotifier: Error cleaning up user data: $e');
      }
      // Continue with cleanup even if sync cleanup fails
    }
  }
  
  // Auth methods
  Future<void> signInWithEmail(String email, String password) async {
    if (kDebugMode) {
      print('🔥 FirebaseAuthNotifier: Signing in with email');
    }
    
    state = const AuthState.loading();
    try {
      await _authService!.signInWithEmail(email, password);
      // State will be updated by the auth stream listener
    } catch (e) {
      if (kDebugMode) {
        print('🔥 FirebaseAuthNotifier: Sign in error - $e');
      }
      state = AuthState.unauthenticated(e.toString());
    }
  }
  
  Future<void> registerWithEmail(String email, String password, String name) async {
    if (kDebugMode) {
      print('🔥 FirebaseAuthNotifier: Registering with email');
    }
    
    state = const AuthState.loading();
    try {
      await _authService!.registerWithEmail(email, password, name);
      // State will be updated by the auth stream listener
    } catch (e) {
      if (kDebugMode) {
        print('🔥 FirebaseAuthNotifier: Registration error - $e');
      }
      state = AuthState.unauthenticated(e.toString());
    }
  }
  
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _authService!.sendPasswordResetEmail(email);
      if (kDebugMode) {
        print('🔥 FirebaseAuthNotifier: Password reset email sent');
      }
    } catch (e) {
      if (kDebugMode) {
        print('🔥 FirebaseAuthNotifier: Password reset error - $e');
      }
      rethrow;
    }
  }
  
  Future<void> signInWithGoogle() async {
    if (kDebugMode) {
      print('🔥 FirebaseAuthNotifier: Signing in with Google');
    }
    
    state = const AuthState.loading();
    try {
      await _authService!.signInWithGoogle();
      // State will be updated by the auth stream listener
    } catch (e) {
      if (kDebugMode) {
        print('🔥 FirebaseAuthNotifier: Google sign in error - $e');
      }
      state = AuthState.unauthenticated(e.toString());
    }
  }

  /// Link Google account to existing email/password account
  Future<void> linkGoogleAccount() async {
    if (kDebugMode) {
      print('🔥 FirebaseAuthNotifier: Linking Google account');
    }
    
    try {
      await _authService!.linkGoogleAccount();
      if (kDebugMode) {
        print('🔥 FirebaseAuthNotifier: Google account linked successfully');
      }
      // State will be updated by the auth stream listener
    } catch (e) {
      if (kDebugMode) {
        print('🔥 FirebaseAuthNotifier: Google account linking error - $e');
      }
      // Re-throw to let the UI handle the error
      rethrow;
    }
  }
  
  Future<void> signOut() async {
    if (kDebugMode) {
      print('🔥 FirebaseAuthNotifier: Signing out');
    }
    
    try {
      await _authService!.signOut();
      // State will be updated by the auth stream listener
    } catch (e) {
      if (kDebugMode) {
        print('🔥 FirebaseAuthNotifier: Sign out error - $e');
      }
    }
  }
  
}

// Providers
final firebaseAuthServiceProvider = Provider<FirebaseAuthService>((ref) {
  return FirebaseAuthService();
});

final firebaseAuthProvider = NotifierProvider<FirebaseAuthNotifier, AuthState>(() {
  return FirebaseAuthNotifier();
});