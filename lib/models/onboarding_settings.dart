import 'package:hive/hive.dart';

part 'onboarding_settings.g.dart';

@HiveType(typeId: 9)
class OnboardingSettings extends HiveObject {
  @HiveField(0)
  final String coachName;
  
  @HiveField(1)
  final String seasonName;
  
  @HiveField(2)
  final String teamName;
  
  @HiveField(3)
  final bool isCompleted;

  OnboardingSettings({
    required this.coachName,
    required this.seasonName,
    required this.teamName,
    required this.isCompleted,
  });

  factory OnboardingSettings.create({
    required String coachName,
    required String seasonName,
    required String teamName,
  }) {
    return OnboardingSettings(
      coachName: coachName,
      seasonName: seasonName,
      teamName: teamName,
      isCompleted: true,
    );
  }
}