import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:coachmaster/services/analytics_service.dart';

class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    // Let GoogleSignIn auto-detect the client ID from Firebase configuration
    // For Android, the client ID will be automatically detected from google-services.json
    // Scopes for accessing user info
    scopes: [
      'email',
      'profile',
    ],
  );
  
  // Prevent concurrent Google Sign-In operations
  bool _isGoogleSignInInProgress = false;
  
  // Simple email/password authentication
  Future<UserCredential?> signInWithEmail(String email, String password) async {
    try {
      if (kDebugMode) {
        print('🔥 FirebaseAuth: Attempting sign in for ${email.trim().toLowerCase()}');
      }
      
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim().toLowerCase(),
        password: password
      );

      // Track successful login
      await AnalyticsService.logLogin(method: 'email');
      await AnalyticsService.setUserId(credential.user?.uid ?? '');

      return credential;
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        print('🔥 FirebaseAuth: Sign in failed - ${e.code}: ${e.message}');
      }
      throw _handleAuthException(e);
    }
  }
  
  Future<UserCredential?> registerWithEmail(String email, String password, String name) async {
    try {
      if (kDebugMode) {
        print('🔥 FirebaseAuth: Attempting registration for ${email.trim().toLowerCase()}');
      }
      
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim().toLowerCase(), 
        password: password
      );
      
      // Update user profile with name
      await credential.user?.updateDisplayName(name);

      // Track successful registration
      await AnalyticsService.logSignUp(method: 'email');
      await AnalyticsService.setUserId(credential.user?.uid ?? '');

      if (kDebugMode) {
        print('🔥 FirebaseAuth: Registration successful for ${credential.user?.email}');
      }
      
      return credential;
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        print('🔥 FirebaseAuth: Registration failed - ${e.code}: ${e.message}');
      }
      throw _handleAuthException(e);
    }
  }
  
  User? getCurrentUser() {
    final user = _auth.currentUser;
    if (kDebugMode && user != null) {
      debugPrint('🔥 FirebaseAuth: Current user - ${user.email}');
    }
    return user;
  }
  
  // Getter alias for currentUser
  User? get currentUser => getCurrentUser();
  
  Stream<User?> authStateChanges() {
    return _auth.authStateChanges().map((user) {
      if (kDebugMode) {
        print('🔥 FirebaseAuth: Auth state changed - ${user?.email ?? 'null'}');
      }
      return user;
    });
  }
  
  
  // Google Sign-In authentication
  Future<UserCredential?> signInWithGoogle() async {
    // Prevent concurrent sign-in operations
    if (_isGoogleSignInInProgress) {
      if (kDebugMode) {
        print('🔥 FirebaseAuth: Google Sign-In already in progress, skipping...');
      }
      return null;
    }
    
    try {
      _isGoogleSignInInProgress = true;
      
      if (kDebugMode) {
        print('🔥 FirebaseAuth: Attempting Google Sign-In');
      }
      
      GoogleSignInAccount? googleUser;
      
      // Use only interactive sign-in to avoid race conditions
      try {
        googleUser = await _googleSignIn.signIn();
        if (kDebugMode) {
          print('🔥 FirebaseAuth: Interactive sign-in completed');
        }
      } catch (e) {
        if (kDebugMode) {
          print('🔥 FirebaseAuth: Interactive sign-in failed: $e');
        }
        // On web, provide specific guidance for FedCM
        if (kIsWeb && e.toString().contains('popup')) {
          throw Exception('Google Sign-In requires popup access. Please allow popups and try again.');
        }
        rethrow;
      }
      
      if (googleUser == null) {
        // User cancelled the sign-in
        if (kDebugMode) {
          print('🔥 FirebaseAuth: Google Sign-In cancelled by user');
        }
        return null;
      }
      
      // Check if this email already exists with email/password authentication
      final email = googleUser.email;
      if (kDebugMode) {
        print('🔥 FirebaseAuth: Checking if email $email already exists');
      }
      
      // We'll handle email conflicts during the actual sign-in process
      // Firebase will automatically detect if there's a conflict
      
      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      
      // Sign in to Firebase with the Google credential
      final userCredential = await _auth.signInWithCredential(credential);

      // Track successful Google sign-in
      await AnalyticsService.logLogin(method: 'google');
      await AnalyticsService.setUserId(userCredential.user?.uid ?? '');

      if (kDebugMode) {
        print('🔥 FirebaseAuth: Google Sign-In successful for ${userCredential.user?.email}');
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        print('🔥 FirebaseAuth: Google Sign-In failed - ${e.code}: ${e.message}');
      }
      
      // Handle account exists with different credential
      if (e.code == 'account-exists-with-different-credential') {
        // Sign out from Google since we can't proceed
        await _googleSignIn.signOut();
        
        throw Exception(
          'An account with this email already exists. Please sign in with your email and password instead, '
          'or contact support to link your Google account.'
        );
      }
      
      throw _handleAuthException(e);
    } catch (e) {
      if (kDebugMode) {
        print('🔥 FirebaseAuth: Google Sign-In error - $e');
      }
      
      // Handle specific web popup errors
      if (e.toString().contains('popup_closed')) {
        throw Exception('Google Sign-In popup was closed. Please try again and allow the popup to complete.');
      } else if (e.toString().contains('popup_blocked')) {
        throw Exception('Popup blocked by browser. Please allow popups for this site and try again.');
      }
      
      throw Exception('Google Sign-In failed: $e');
    } finally {
      _isGoogleSignInInProgress = false;
    }
  }

  // Sign out from both Firebase and Google
  Future<void> signOut() async {
    if (kDebugMode) {
      print('🔥 FirebaseAuth: Signing out user - ${_auth.currentUser?.email}');
    }
    
    try {
      // Sign out from Google completely (including silent sign-in)
      if (await _googleSignIn.isSignedIn()) {
        await _googleSignIn.signOut();
      }
      
      // Also clear Google Sign-In cache to prevent silent sign-in
      await _googleSignIn.disconnect();
      
      // Sign out from Firebase and clear persistence
      await _auth.signOut();
      
      if (kDebugMode) {
        print('🔥 FirebaseAuth: Complete sign out successful');
      }
      
    } catch (e) {
      if (kDebugMode) {
        print('🔥 FirebaseAuth: Sign out error - $e');
      }
      // Still try to sign out from Firebase even if Google sign out fails
      try {
        await _auth.signOut();
      } catch (finalError) {
        if (kDebugMode) {
          print('🔥 FirebaseAuth: Final sign out attempt failed - $finalError');
        }
      }
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      if (kDebugMode) {
        print('🔥 FirebaseAuth: Sending password reset email to ${email.trim().toLowerCase()}');
      }
      await _auth.sendPasswordResetEmail(email: email.trim().toLowerCase());
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        print('🔥 FirebaseAuth: Password reset failed - ${e.code}: ${e.message}');
      }
      throw _handleAuthException(e);
    }
  }

  /// Link Google account to existing email/password account
  /// User must be signed in with email/password first
  Future<UserCredential?> linkGoogleAccount() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('You must be signed in to link your Google account.');
    }

    try {
      if (kDebugMode) {
        print('🔥 FirebaseAuth: Attempting to link Google account for ${currentUser.email}');
      }

      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        if (kDebugMode) {
          print('🔥 FirebaseAuth: Google Sign-In cancelled by user during linking');
        }
        return null;
      }

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Link the Google credential to the current user
      final userCredential = await currentUser.linkWithCredential(credential);
      
      if (kDebugMode) {
        print('🔥 FirebaseAuth: Google account linked successfully for ${userCredential.user?.email}');
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        print('🔥 FirebaseAuth: Google account linking failed - ${e.code}: ${e.message}');
      }
      throw _handleAuthException(e);
    } catch (e) {
      if (kDebugMode) {
        print('🔥 FirebaseAuth: Google account linking error - $e');
      }
      throw Exception('Failed to link Google account: $e');
    }
  }
  
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email address.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'email-already-in-use':
        return 'An account already exists with this email address.';
      case 'weak-password':
        return 'Password is too weak. Please use at least 6 characters.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later.';
      case 'operation-not-allowed':
        return 'Email/password sign in is not enabled.';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection.';
      default:
        if (kDebugMode) {
          print('🔥 FirebaseAuth: Unhandled error code: ${e.code}');
        }
        return 'Authentication error: ${e.message ?? 'Unknown error'}';
    }
  }
}