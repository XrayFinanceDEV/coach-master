class Season {
  final String id;
  final String name;
  final DateTime startDate;
  final DateTime endDate;

  Season({
    required this.id,
    required this.name,
    required this.startDate,
    required this.endDate,
  });

  // Basic factory for generating unique IDs and default dates
  factory Season.create({
    required String name,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    final now = DateTime.now();
    return Season(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      startDate: startDate ?? DateTime(now.year, 7, 1), // July 1st default
      endDate: endDate ?? DateTime(now.year + 1, 6, 30), // June 30th next year default
    );
  }

  // JSON serialization for Firestore
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
    };
  }

  factory Season.fromJson(Map<String, dynamic> json) {
    return Season(
      id: json['id'] as String,
      name: json['name'] as String,
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
    );
  }
}
