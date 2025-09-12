import 'package:hive/hive.dart';

part 'user.g.dart';

@HiveType(typeId: 14)
class User extends HiveObject {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String name;
  
  @HiveField(2)
  final String email;
  
  @HiveField(3)
  final String passwordHash;
  
  @HiveField(4)
  final String? currentSeasonId;
  
  @HiveField(5)
  final String? currentTeamId;
  
  @HiveField(6)
  final DateTime createdAt;
  
  @HiveField(7)
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
}