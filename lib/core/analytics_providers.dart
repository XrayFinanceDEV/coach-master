import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coachmaster/services/analytics_service.dart';

// Provider for analytics service
final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  return AnalyticsService();
});

// Provider for tracking feature usage
final analyticsProvider = Provider<AnalyticsHelper>((ref) {
  return AnalyticsHelper();
});

class AnalyticsHelper {
  // Track player-related events
  Future<void> trackPlayerCreated() async {
    await AnalyticsService.logPlayerAdded();
  }

  Future<void> trackPlayerPhotoUpdated() async {
    await AnalyticsService.logPlayerPhotoUpdated();
  }

  // Track team management events
  Future<void> trackTeamCreated() async {
    await AnalyticsService.logTeamCreated();
  }

  Future<void> trackSeasonCreated() async {
    await AnalyticsService.logSeasonCreated();
  }

  // Track training events
  Future<void> trackTrainingCreated() async {
    await AnalyticsService.logTrainingCreated();
  }

  Future<void> trackTrainingAttendanceUpdated(int attendees) async {
    await AnalyticsService.logTrainingAttendanceUpdated(attendees: attendees);
  }

  // Track match events
  Future<void> trackMatchCreated() async {
    await AnalyticsService.logMatchCreated();
  }

  Future<void> trackMatchCompleted({
    required int goalsFor,
    required int goalsAgainst,
    required String result,
  }) async {
    await AnalyticsService.logMatchCompleted(
      goalsFor: goalsFor,
      goalsAgainst: goalsAgainst,
      result: result,
    );
  }

  Future<void> trackMatchStatsSaved(int playersWithStats) async {
    await AnalyticsService.logMatchStatsSaved(playersWithStats: playersWithStats);
  }

  // Track notes events
  Future<void> trackNoteCreated(String noteType) async {
    await AnalyticsService.logNoteCreated(noteType: noteType);
  }

  // Track feature usage
  Future<void> trackFeatureUsed(String featureName) async {
    await AnalyticsService.logFeatureUsed(featureName: featureName);
  }

  // Track errors
  Future<void> trackError(String errorType, [String? errorMessage]) async {
    await AnalyticsService.logError(
      errorType: errorType,
      errorMessage: errorMessage,
    );
  }

  // Track language changes
  Future<void> trackLanguageChanged(String language) async {
    await AnalyticsService.logLanguageChanged(language: language);
  }
}