class Team {
  final String id;
  final String seasonId;
  final String name;
  final String? description;
  final String? logoPath; // Local path to the logo file

  Team({
    required this.id,
    required this.seasonId,
    required this.name,
    this.description,
    this.logoPath,
  });

  factory Team.create({
    required String name,
    required String seasonId,
    String? description,
    String? logoPath,
  }) {
    return Team(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      seasonId: seasonId,
      name: name,
      description: description,
      logoPath: logoPath,
    );
  }

  // JSON serialization for Firestore
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'seasonId': seasonId,
      'name': name,
      'description': description,
      'logoPath': logoPath,
    };
  }

  factory Team.fromJson(Map<String, dynamic> json) {
    return Team(
      id: json['id'] as String,
      seasonId: json['seasonId'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      logoPath: json['logoPath'] as String?,
    );
  }
}
