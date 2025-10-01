class Player {
  final String id;
  final String teamId;
  final String firstName;
  final String lastName;
  final String position;
  final String preferredFoot;
  final DateTime birthDate;
  final String? photoPath; // Local path to player photo
  final Map<String, dynamic>? medicalInfo;
  final Map<String, dynamic>? emergencyContact;
  // Statistical fields
  final int goals;
  final int assists;
  final int yellowCards;
  final int redCards;
  final int totalMinutes;
  final double? avgRating;
  final int absences;

  Player({
    required this.id,
    required this.teamId,
    required this.firstName,
    required this.lastName,
    required this.position,
    required this.preferredFoot,
    required this.birthDate,
    this.photoPath,
    this.medicalInfo,
    this.emergencyContact,
    this.goals = 0,
    this.assists = 0,
    this.yellowCards = 0,
    this.redCards = 0,
    this.totalMinutes = 0,
    this.avgRating,
    this.absences = 0,
  });

  factory Player.create({
    required String teamId,
    required String firstName,
    required String lastName,
    String position = 'Unknown',
    String preferredFoot = 'Both',
    required DateTime birthDate,
    String? photoPath,
    Map<String, dynamic>? medicalInfo,
    Map<String, dynamic>? emergencyContact,
    int goals = 0,
    int assists = 0,
    int yellowCards = 0,
    int redCards = 0,
    int totalMinutes = 0,
    double? avgRating,
    int absences = 0,
  }) {
    return Player(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      teamId: teamId,
      firstName: firstName,
      lastName: lastName,
      position: position,
      preferredFoot: preferredFoot,
      birthDate: birthDate,
      photoPath: photoPath,
      medicalInfo: medicalInfo,
      emergencyContact: emergencyContact,
      goals: goals,
      assists: assists,
      yellowCards: yellowCards,
      redCards: redCards,
      totalMinutes: totalMinutes,
      avgRating: avgRating,
      absences: absences,
    );
  }

  // Convenience method to update statistics
  Player updateStatistics({
    int? goals,
    int? assists,
    int? yellowCards,
    int? redCards,
    int? totalMinutes,
    double? avgRating,
    int? absences,
  }) {
    return Player(
      id: id,
      teamId: teamId,
      firstName: firstName,
      lastName: lastName,
      position: position,
      preferredFoot: preferredFoot,
      birthDate: birthDate,
      photoPath: photoPath,
      medicalInfo: medicalInfo,
      emergencyContact: emergencyContact,
      goals: goals ?? this.goals,
      assists: assists ?? this.assists,
      yellowCards: yellowCards ?? this.yellowCards,
      redCards: redCards ?? this.redCards,
      totalMinutes: totalMinutes ?? this.totalMinutes,
      avgRating: avgRating ?? this.avgRating,
      absences: absences ?? this.absences,
    );
  }

  // JSON serialization for Firestore
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'teamId': teamId,
      'firstName': firstName,
      'lastName': lastName,
      'position': position,
      'preferredFoot': preferredFoot,
      'birthDate': birthDate.toIso8601String(),
      'photoPath': photoPath,
      'medicalInfo': medicalInfo,
      'emergencyContact': emergencyContact,
      'goals': goals,
      'assists': assists,
      'yellowCards': yellowCards,
      'redCards': redCards,
      'totalMinutes': totalMinutes,
      'avgRating': avgRating,
      'absences': absences,
    };
  }

  factory Player.fromJson(Map<String, dynamic> json) {
    return Player(
      id: json['id'] as String,
      teamId: json['teamId'] as String,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      position: json['position'] as String,
      preferredFoot: json['preferredFoot'] as String,
      birthDate: DateTime.parse(json['birthDate'] as String),
      photoPath: json['photoPath'] as String?,
      medicalInfo: json['medicalInfo'] as Map<String, dynamic>?,
      emergencyContact: json['emergencyContact'] as Map<String, dynamic>?,
      goals: (json['goals'] as num?)?.toInt() ?? 0,
      assists: (json['assists'] as num?)?.toInt() ?? 0,
      yellowCards: (json['yellowCards'] as num?)?.toInt() ?? 0,
      redCards: (json['redCards'] as num?)?.toInt() ?? 0,
      totalMinutes: (json['totalMinutes'] as num?)?.toInt() ?? 0,
      avgRating: (json['avgRating'] as num?)?.toDouble(),
      absences: (json['absences'] as num?)?.toInt() ?? 0,
    );
  }
}
