import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

class AnalyticsService {
  static final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  static FirebaseAnalyticsObserver get observer => FirebaseAnalyticsObserver(analytics: _analytics);

  // User Events
  static Future<void> logLogin({required String method}) async {
    await _analytics.logLogin(loginMethod: method);
    if (kDebugMode) {
      print('Analytics: Login - Method: $method');
    }
  }

  static Future<void> logSignUp({required String method}) async {
    await _analytics.logSignUp(signUpMethod: method);
    if (kDebugMode) {
      print('Analytics: Sign Up - Method: $method');
    }
  }

  // Team Management Events
  static Future<void> logTeamCreated() async {
    await _analytics.logEvent(
      name: 'team_created',
      parameters: {},
    );
    if (kDebugMode) {
      print('Analytics: Team Created');
    }
  }

  static Future<void> logSeasonCreated() async {
    await _analytics.logEvent(
      name: 'season_created',
      parameters: {},
    );
    if (kDebugMode) {
      print('Analytics: Season Created');
    }
  }

  // Player Management Events
  static Future<void> logPlayerAdded() async {
    await _analytics.logEvent(
      name: 'player_added',
      parameters: {},
    );
    if (kDebugMode) {
      print('Analytics: Player Added');
    }
  }

  static Future<void> logPlayerPhotoUpdated() async {
    await _analytics.logEvent(
      name: 'player_photo_updated',
      parameters: {},
    );
    if (kDebugMode) {
      print('Analytics: Player Photo Updated');
    }
  }

  // Training Events
  static Future<void> logTrainingCreated() async {
    await _analytics.logEvent(
      name: 'training_created',
      parameters: {},
    );
    if (kDebugMode) {
      print('Analytics: Training Created');
    }
  }

  static Future<void> logTrainingAttendanceUpdated({required int attendees}) async {
    await _analytics.logEvent(
      name: 'training_attendance_updated',
      parameters: {'attendees': attendees},
    );
    if (kDebugMode) {
      print('Analytics: Training Attendance Updated - Attendees: $attendees');
    }
  }

  // Match Events
  static Future<void> logMatchCreated() async {
    await _analytics.logEvent(
      name: 'match_created',
      parameters: {},
    );
    if (kDebugMode) {
      print('Analytics: Match Created');
    }
  }

  static Future<void> logMatchCompleted({
    required int goalsFor,
    required int goalsAgainst,
    required String result,
  }) async {
    await _analytics.logEvent(
      name: 'match_completed',
      parameters: {
        'goals_for': goalsFor,
        'goals_against': goalsAgainst,
        'result': result,
      },
    );
    if (kDebugMode) {
      print('Analytics: Match Completed - $goalsFor:$goalsAgainst ($result)');
    }
  }

  static Future<void> logMatchStatsSaved({required int playersWithStats}) async {
    await _analytics.logEvent(
      name: 'match_stats_saved',
      parameters: {'players_with_stats': playersWithStats},
    );
    if (kDebugMode) {
      print('Analytics: Match Stats Saved - Players: $playersWithStats');
    }
  }

  // Notes Events
  static Future<void> logNoteCreated({required String noteType}) async {
    await _analytics.logEvent(
      name: 'note_created',
      parameters: {'note_type': noteType},
    );
    if (kDebugMode) {
      print('Analytics: Note Created - Type: $noteType');
    }
  }

  // Navigation Events
  static Future<void> logScreenView({required String screenName}) async {
    await _analytics.logScreenView(screenName: screenName);
    if (kDebugMode) {
      print('Analytics: Screen View - $screenName');
    }
  }

  // Feature Usage Events
  static Future<void> logFeatureUsed({required String featureName}) async {
    await _analytics.logEvent(
      name: 'feature_used',
      parameters: {'feature_name': featureName},
    );
    if (kDebugMode) {
      print('Analytics: Feature Used - $featureName');
    }
  }

  // Error Events
  static Future<void> logError({
    required String errorType,
    String? errorMessage,
  }) async {
    await _analytics.logEvent(
      name: 'app_error',
      parameters: {
        'error_type': errorType,
        if (errorMessage != null) 'error_message': errorMessage,
      },
    );
    if (kDebugMode) {
      print('Analytics: Error - $errorType: $errorMessage');
    }
  }

  // Settings Events
  static Future<void> logLanguageChanged({required String language}) async {
    await _analytics.logEvent(
      name: 'language_changed',
      parameters: {'language': language},
    );
    if (kDebugMode) {
      print('Analytics: Language Changed - $language');
    }
  }

  // Set user properties
  static Future<void> setUserProperty({
    required String name,
    required String value,
  }) async {
    await _analytics.setUserProperty(name: name, value: value);
    if (kDebugMode) {
      print('Analytics: User Property Set - $name: $value');
    }
  }

  // Set user ID (when user logs in)
  static Future<void> setUserId(String userId) async {
    await _analytics.setUserId(id: userId);
    if (kDebugMode) {
      print('Analytics: User ID Set - $userId');
    }
  }
}