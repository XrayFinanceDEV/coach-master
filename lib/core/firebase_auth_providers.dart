import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:coachmaster/services/firebase_auth_service.dart';
import 'package:coachmaster/services/sync_manager.dart';
import 'package:coachmaster/models/auth_state.dart';

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
    
    // 2. Initialize user-specific data storage (for now, just set ready state)
    // TODO: Initialize user-specific repositories in Phase 5
    await _initializeUserData(firebaseUser.uid);
    
    // 3. Set authenticated state ready
    state = AuthState.firebaseAuthenticated(firebaseUser, isInitializing: false);
    
    if (kDebugMode) {
      print('🔥 FirebaseAuthNotifier: User initialization complete');
    }
  }
  
  Future<void> _handleUserSignedOut() async {
    if (kDebugMode) {
      print('🔥 FirebaseAuthNotifier: User signed out');
    }
    
    // 1. Clean up user-specific data (for now, just set unauthenticated)
    // TODO: Close user-specific Hive boxes in Phase 5
    await _cleanupUserData();
    
    // 2. Set unauthenticated state
    state = const AuthState.unauthenticated();
  }
  
  Future<void> _initializeUserData(String userId) async {
    if (kDebugMode) {
      print('🔥 FirebaseAuthNotifier: Initializing user data for $userId');
    }
    
    try {
      // Get Firebase user from auth service
      final firebaseUser = _authService?.currentUser;
      if (firebaseUser == null) {
        throw Exception('Firebase user is null during initialization');
      }
      
      // Initialize SyncManager for the authenticated user
      await SyncManager.instance.initializeForUser(firebaseUser);
      
      if (kDebugMode) {
        print('🔥 FirebaseAuthNotifier: SyncManager initialized for user $userId');
      }
      
      // Perform initial sync to get user data from Firestore
      // Force download ensures cross-device data sync works properly
      await SyncManager.instance.forceDownloadAll();
      
      // Also perform bidirectional sync to upload any local changes
      await SyncManager.instance.performFullSync();
      
      if (kDebugMode) {
        print('🔥 FirebaseAuthNotifier: Initial sync completed for user $userId');
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
      // Clean up SyncManager when user signs out
      await SyncManager.instance.cleanup();
      
      if (kDebugMode) {
        print('🔥 FirebaseAuthNotifier: SyncManager cleaned up');
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