# Firebase Analytics Setup

## Overview
Firebase Analytics has been successfully integrated into CoachMaster to track user behavior, feature usage, and app performance.

## Configuration Files
- `android/app/google-services.json` - Android configuration (updated with Analytics settings)
- `lib/firebase_options.dart` - Platform-specific Firebase configuration
- `pubspec.yaml` - Added `firebase_analytics: ^12.0.1` dependency

## Analytics Service
The `AnalyticsService` class (`lib/services/analytics_service.dart`) provides methods for tracking:

### User Events
- `logLogin(method)` - Track user logins
- `logSignUp(method)` - Track user registrations
- `setUserId(userId)` - Set user identifier for tracking

### Team Management
- `logTeamCreated()` - Track team creation
- `logSeasonCreated()` - Track season creation

### Player Management
- `logPlayerAdded()` - Track when players are added
- `logPlayerPhotoUpdated()` - Track player photo updates

### Training Events
- `logTrainingCreated()` - Track training session creation
- `logTrainingAttendanceUpdated(attendees)` - Track attendance updates

### Match Events
- `logMatchCreated()` - Track match creation
- `logMatchCompleted(goalsFor, goalsAgainst, result)` - Track match completion
- `logMatchStatsSaved(playersWithStats)` - Track statistics saving

### Feature Usage
- `logFeatureUsed(featureName)` - Track feature usage
- `logScreenView(screenName)` - Track screen navigation
- `logNoteCreated(noteType)` - Track note creation

### Error Tracking
- `logError(errorType, errorMessage)` - Track app errors

## Current Integrations

### Authentication
Analytics tracking has been added to:
- Email/password sign-in and registration
- Google Sign-In
- User ID setting for session tracking

### Player Management
- Player creation tracking in `PlayerSyncRepository`
- Automatic analytics calls when players are added

### Router Integration
- `FirebaseAnalyticsObserver` added to GoRouter for automatic screen tracking
- All screen navigation is automatically tracked

## Usage Examples

```dart
// Track feature usage
await AnalyticsService.logFeatureUsed(featureName: 'speed_dial_fab');

// Track custom events
await AnalyticsService.logMatchCompleted(
  goalsFor: 3,
  goalsAgainst: 1,
  result: 'win',
);

// Track errors
await AnalyticsService.logError(
  errorType: 'sync_failure',
  errorMessage: 'Failed to sync player data',
);
```

## Analytics Helper
The `AnalyticsHelper` class (`lib/core/analytics_providers.dart`) provides convenient Riverpod providers for dependency injection:

```dart
// In your widget
final analytics = ref.read(analyticsProvider);
await analytics.trackPlayerCreated();
```

## Debug Mode
All analytics events include debug logging when running in debug mode. Check the console for analytics event confirmations.

## Privacy Considerations
- User IDs are set only after successful authentication
- No personally identifiable information is logged
- All events follow Firebase Analytics privacy guidelines

## Testing Analytics
1. Run the app in debug mode
2. Perform various actions (login, create players, etc.)
3. Check console logs for analytics event confirmations
4. View data in Firebase Console after 24-48 hours

## Next Steps
Consider adding analytics to:
- Settings changes (language, preferences)
- Export features
- Advanced statistics usage
- Error recovery actions