import 'package:hive/hive.dart';

part 'season.g.dart';

@HiveType(typeId: 0)
class Season {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String name;
  @HiveField(2)
  final DateTime startDate;
  @HiveField(3)
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
}
