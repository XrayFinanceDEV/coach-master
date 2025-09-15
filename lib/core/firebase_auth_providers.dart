import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:coachmaster/services/firebase_auth_service.dart';
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
    // Placeholder for user-specific repository initialization
    // This will be implemented in Phase 5 when we enhance repositories
    if (kDebugMode) {
      print('🔥 FirebaseAuthNotifier: Initializing user data for $userId');
    }
    
    // For now, just add a small delay to simulate initialization
    await Future.delayed(const Duration(milliseconds: 500));
  }
  
  Future<void> _cleanupUserData() async {
    // Placeholder for user-specific data cleanup
    // This will be implemented in Phase 5 when we enhance repositories
    if (kDebugMode) {
      print('🔥 FirebaseAuthNotifier: Cleaning up user data');
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