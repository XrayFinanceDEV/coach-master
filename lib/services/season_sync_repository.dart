import 'package:coachmaster/models/season.dart';
import 'package:coachmaster/services/base_sync_repository.dart';
import 'package:coachmaster/services/firestore_sync_service.dart';

class SeasonSyncRepository extends BaseSyncRepository<Season> {
  SeasonSyncRepository({FirestoreSyncService? syncService}) 
    : super(
        boxName: 'seasons',
        entityType: 'seasons',
        syncService: syncService,
      );

  // Legacy methods for backward compatibility
  Future<void> init() async {
    // This will be replaced by initForUser() when sync is enabled
    if (!isInitialized) {
      throw Exception('SeasonSyncRepository: Use initForUser() instead of init() for sync support');
    }
  }

  List<Season> getSeasons() => getAll();
  Season? getSeason(String id) => get(id);

  // Enhanced methods with sync support
  Future<void> addSeason(Season season) async {
    await addWithSync(season);
  }

  Future<void> updateSeason(Season season) async {
    await updateWithSync(season);
  }

  Future<void> deleteSeason(String id) async {
    await deleteWithSync(id);
  }

  // Additional query methods
  List<Season> getSeasonsForYear(int year) {
    return getAll().where((season) {
      return season.startDate.year == year;
    }).toList();
  }

  Season? getCurrentSeason() {
    final seasons = getAll();
    if (seasons.isEmpty) return null;
    
    // Sort by start date and return the most recent
    seasons.sort((a, b) => b.startDate.compareTo(a.startDate));
    return seasons.first;
  }

  // Implementation of abstract methods from BaseSyncRepository
  @override
  String getEntityId(Season item) => item.id;

  @override
  Map<String, dynamic> toMap(Season item) {
    return {
      'id': item.id,
      'name': item.name,
      'startDate': item.startDate.toIso8601String(),
      'endDate': item.endDate.toIso8601String(),
    };
  }

  @override
  Season fromMap(Map<String, dynamic> map) {
    return Season(
      id: map['id'] as String,
      name: map['name'] as String,
      startDate: DateTime.parse(map['startDate'] as String),
      endDate: DateTime.parse(map['endDate'] as String),
    );
  }
}