import 'package:coachmaster/models/user.dart';

enum AuthStatus {
  unauthenticated,
  authenticated,
  loading,
}

class AuthState {
  final AuthStatus status;
  final User? user;
  final String? errorMessage;

  const AuthState({
    required this.status,
    this.user,
    this.errorMessage,
  });

  const AuthState.initial() : this(
    status: AuthStatus.unauthenticated,
    user: null,
    errorMessage: null,
  );

  const AuthState.loading() : this(
    status: AuthStatus.loading,
    user: null,
    errorMessage: null,
  );

  const AuthState.authenticated(User user) : this(
    status: AuthStatus.authenticated,
    user: user,
    errorMessage: null,
  );

  const AuthState.unauthenticated([String? errorMessage]) : this(
    status: AuthStatus.unauthenticated,
    user: null,
    errorMessage: errorMessage,
  );

  bool get isAuthenticated => status == AuthStatus.authenticated && user != null;
  bool get isLoading => status == AuthStatus.loading;
  bool get hasError => errorMessage != null;
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