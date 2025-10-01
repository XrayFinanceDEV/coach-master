class User {
  final String id;
  final String name;
  final String email;
  final String passwordHash;
  final String? currentSeasonId;
  final String? currentTeamId;
  final DateTime createdAt;
  final bool isOnboardingCompleted;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.passwordHash,
    this.currentSeasonId,
    this.currentTeamId,
    required this.createdAt,
    required this.isOnboardingCompleted,
  });

  factory User.create({
    required String name,
    required String email,
    required String passwordHash,
    String? currentSeasonId,
    String? currentTeamId,
    bool isOnboardingCompleted = false,
  }) {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    return User(
      id: id,
      name: name,
      email: email,
      passwordHash: passwordHash,
      currentSeasonId: currentSeasonId,
      currentTeamId: currentTeamId,
      createdAt: DateTime.now(),
      isOnboardingCompleted: isOnboardingCompleted,
    );
  }

  User copyWith({
    String? id,
    String? name,
    String? email,
    String? passwordHash,
    String? currentSeasonId,
    String? currentTeamId,
    DateTime? createdAt,
    bool? isOnboardingCompleted,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      passwordHash: passwordHash ?? this.passwordHash,
      currentSeasonId: currentSeasonId ?? this.currentSeasonId,
      currentTeamId: currentTeamId ?? this.currentTeamId,
      createdAt: createdAt ?? this.createdAt,
      isOnboardingCompleted: isOnboardingCompleted ?? this.isOnboardingCompleted,
    );
  }

  // JSON serialization for Firestore
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'passwordHash': passwordHash,
      'currentSeasonId': currentSeasonId,
      'currentTeamId': currentTeamId,
      'createdAt': createdAt.toIso8601String(),
      'isOnboardingCompleted': isOnboardingCompleted,
    };
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      passwordHash: json['passwordHash'] as String,
      currentSeasonId: json['currentSeasonId'] as String?,
      currentTeamId: json['currentTeamId'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      isOnboardingCompleted: json['isOnboardingCompleted'] as bool,
    );
  }
}
