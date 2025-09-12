import 'package:hive_flutter/hive_flutter.dart';
import 'package:coachmaster/models/season.dart';
class SeasonRepository {
  late Box<Season> _seasonBox;

  Future<void> init() async {
    _seasonBox = await Hive.openBox<Season>('seasons');
  }

  List<Season> getSeasons() {
    return _seasonBox.values.toList();
  }

  Season? getSeason(String id) {
    return _seasonBox.get(id);
  }

  Future<void> addSeason(Season season) async {
    await _seasonBox.put(season.id, season);
  }

  Future<void> updateSeason(Season season) async {
    await _seasonBox.put(season.id, season);
  }

  Future<void> deleteSeason(String id) async {
    await _seasonBox.delete(id);
  }
}