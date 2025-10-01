class OnboardingSettings {
  final String coachName;
  final String seasonName;
  final String teamName;
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

  // JSON serialization for Firestore
  Map<String, dynamic> toJson() {
    return {
      'coachName': coachName,
      'seasonName': seasonName,
      'teamName': teamName,
      'isCompleted': isCompleted,
    };
  }

  factory OnboardingSettings.fromJson(Map<String, dynamic> json) {
    return OnboardingSettings(
      coachName: json['coachName'] as String,
      seasonName: json['seasonName'] as String,
      teamName: json['teamName'] as String,
      isCompleted: json['isCompleted'] as bool,
    );
  }
}
