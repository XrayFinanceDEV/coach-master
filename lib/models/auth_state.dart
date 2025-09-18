import 'package:coachmaster/models/user.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

enum AuthStatus {
  unauthenticated,
  authenticated,
  loading,
}

class AuthState {
  final AuthStatus status;
  final User? user; // Local app user (legacy)
  final firebase_auth.User? firebaseUser; // Firebase user
  final String? errorMessage;
  final bool isInitializing; // For Firebase auth initialization

  const AuthState({
    required this.status,
    this.user,
    this.firebaseUser,
    this.errorMessage,
    this.isInitializing = false,
  });

  const AuthState.initial() : this(
    status: AuthStatus.unauthenticated,
    user: null,
    firebaseUser: null,
    errorMessage: null,
    isInitializing: false,
  );

  const AuthState.loading() : this(
    status: AuthStatus.loading,
    user: null,
    firebaseUser: null,
    errorMessage: null,
    isInitializing: false,
  );

  // Legacy constructor for local auth (backward compatibility)
  const AuthState.authenticated(User user) : this(
    status: AuthStatus.authenticated,
    user: user,
    firebaseUser: null,
    errorMessage: null,
    isInitializing: false,
  );

  // New constructor for Firebase auth
  const AuthState.firebaseAuthenticated(firebase_auth.User firebaseUser, {bool isInitializing = false}) : this(
    status: AuthStatus.authenticated,
    user: null,
    firebaseUser: firebaseUser,
    errorMessage: null,
    isInitializing: isInitializing,
  );

  const AuthState.unauthenticated([String? errorMessage]) : this(
    status: AuthStatus.unauthenticated,
    user: null,
    firebaseUser: null,
    errorMessage: errorMessage,
    isInitializing: false,
  );

  // Compatibility getters
  bool get isAuthenticated => status == AuthStatus.authenticated && (user != null || firebaseUser != null);
  bool get isLoading => status == AuthStatus.loading || (status == AuthStatus.authenticated && isInitializing);
  bool get isLoadingState => isLoading; // Alias for FirebaseTestScreen compatibility
  bool get hasError => errorMessage != null;
  bool get isFullyReady => isAuthenticated && !isInitializing;
  
  // Firebase user properties (for new auth system)
  String? get email => firebaseUser?.email ?? user?.email;
  String? get displayName => firebaseUser?.displayName ?? user?.name;
  String? get uid => firebaseUser?.uid;
  
  // Check if using Firebase auth
  bool get isUsingFirebaseAuth => firebaseUser != null;
  bool get isUsingLocalAuth => user != null;
}

enum OnboardingStep {
  personalInfo,
  password,
  teamSetup,
  completed,
}

class OnboardingState {
  final OnboardingStep currentStep;
  final String? name;
  final String? email;
  final String? password;
  final String? confirmPassword;
  final String? seasonName;
  final String? teamName;
  final bool isLoading;
  final String? errorMessage;

  const OnboardingState({
    required this.currentStep,
    this.name,
    this.email,
    this.password,
    this.confirmPassword,
    this.seasonName = '2025-26',
    this.teamName,
    this.isLoading = false,
    this.errorMessage,
  });

  const OnboardingState.initial() : this(
    currentStep: OnboardingStep.personalInfo,
  );

  OnboardingState copyWith({
    OnboardingStep? currentStep,
    String? name,
    String? email,
    String? password,
    String? confirmPassword,
    String? seasonName,
    String? teamName,
    bool? isLoading,
    String? errorMessage,
  }) {
    return OnboardingState(
      currentStep: currentStep ?? this.currentStep,
      name: name ?? this.name,
      email: email ?? this.email,
      password: password ?? this.password,
      confirmPassword: confirmPassword ?? this.confirmPassword,
      seasonName: seasonName ?? this.seasonName,
      teamName: teamName ?? this.teamName,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  bool get canProceedFromPersonalInfo => 
      name != null && name!.trim().isNotEmpty &&
      email != null && email!.trim().isNotEmpty && _isValidEmail(email!);

  bool get canProceedFromPassword => 
      password != null && password!.length >= 6 &&
      confirmPassword != null && password == confirmPassword;

  bool get canCompleteOnboarding => 
      canProceedFromPersonalInfo && canProceedFromPassword &&
      seasonName != null && seasonName!.trim().isNotEmpty &&
      teamName != null && teamName!.trim().isNotEmpty;

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }
}