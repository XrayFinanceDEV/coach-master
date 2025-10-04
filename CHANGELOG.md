# Changelog

All notable changes to CoachMaster will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0+9] - 2025-10-04

### Fixed
- **Match Statistics ID Collision**: Fixed bug where batch-saving match statistics could result in only one player's stats being saved on Android
  - Changed from timestamp-only IDs to compound keys (`matchId_playerId_timestamp`)
  - Prevents ID collisions when creating multiple statistics in quick succession
- **Player Statistics After Match Deletion**: Fixed critical bug where player ratings persisted after deleting all matches
  - Root cause: `updateStatistics()` method used null-coalescing operator that prevented null values from overwriting existing ratings
  - Changed all `updateStatistics()` parameters to required, ensuring explicit values (including null) are always applied
  - Removed `SetOptions(merge: true)` from player updates to ensure null values properly overwrite existing data
- **Match Deletion Flow**: Improved player aggregate statistics recalculation after match deletion
  - Fixed async bug where player stats update wasn't properly awaited
  - Added explicit stream provider invalidation to force fresh data from Firestore
  - Increased propagation delay to 500ms to ensure Firestore streams reflect updated data

### Added
- **Deletion Loading Indicators**: Added circular progress indicators in all delete confirmation dialogs
  - Match deletion (list and detail screens)
  - Training deletion (list and detail screens)
  - Shows white rotating circle in delete button during deletion process
  - Disables both buttons to prevent double-clicks or accidental cancellation
  - Prevents dialog dismissal while deletion is in progress (`barrierDismissible: false`)
  - Includes error handling with user-friendly error messages via snackbar

### Changed
- **Dashboard UI**: Removed "Sort by Position" filter button from player cards section on home screen
  - Players now always sorted by position (default behavior)
  - Cleaner, more streamlined dashboard interface
- **Match Statistics Wizard UI**: Improved player grouping consistency across all steps
  - Steps 4 (Cards & Penalties), 5 (Playing Time), and 6/7 (Ratings) now group players by position like steps 2-3
  - Consistent Attack → Midfield → Defense categorization throughout the wizard
  - Replaced 5-star rating display with color-coded symbols for 1-10 ratings:
    - Red down triangle (▼) for ratings < 5
    - Orange dash (−) for ratings 5-6
    - Green up triangle (▲) for ratings > 7
  - Slider color changes dynamically based on rating value
- **Match List UI**: Simplified match cards
  - Removed "Statistiche salvate" (Statistics saved) badge to reduce card size
  - Retained "Completata" (Completed) status badge
- **Italian Translations**: Improved match-related terminology
  - Renamed player ratings step from "Valutazioni Giocatori" to "Pagelle" (traditional Italian football term)
  - Changed "Casa" to "In Casa" (Home Ground)
  - Changed "Trasferta" to "Fuori Casa" (Away Ground)
  - Added translation helper for legacy location strings to display correctly in current locale
  - Fixed hardcoded English strings in training empty state ("No Training Sessions", "Create First Training")
  - Fixed hardcoded English strings in training deletion dialog

## [1.0.0+8] - 2025-10-03

### Performance
- **Match Statistics Saving**: Implemented Firestore batch writes for 10-20x faster performance
  - Replaced sequential writes with single atomic batch operation
  - Reduced network calls from 20-50+ to 1 batch commit
  - Significantly improved responsiveness on slow connections

### Changed
- Exposed public `toFirestore()` methods in match and statistic repositories for batch operations
- Kept `google_sign_in` at v6.3.0 (v7.x has breaking changes requiring major refactoring)

## [1.0.0+7] - 2025-10-03

### Fixed
- Backward compatibility fix for match dates

## [1.0.0+6] - 2025-10-03

### Changed
- Firebase migration release
- Complete transition to Firestore-only architecture

## [1.0.0+5] - 2025-10-03

### Added
- Complete Firebase migration and localization improvements
- Training attendance sync
- Manual data refresh functionality

### Fixed
- App icon issue with clean build

## [1.0.0+4] - 2025-10-03

### Added
- Sliding team statistics carousel with 2-page layout
- 2x2 grid statistics display

### Fixed
- App icon system issues

## [1.0.0+3] - 2025-10-03

### Added
- Advanced image crop positioning
- Comprehensive Firebase Analytics integration

### Fixed
- Absences counter system
- Player image display bugs in cards

### Changed
- Production configuration updated for Google Play Store release
- Android build configuration (Target SDK 35, Compile SDK 36)

## [1.0.0+2] - 2025-10-03

### Added
- Comprehensive translation system consistency
- Italian/English bilingual support via ARB files

### Fixed
- Overflow in training detail screen player list
- Onboarding flow and team creation
- Web platform TypeError in matches section
- Authentication red screen errors
- Android app startup issues

## [1.0.0+1] - 2025-10-03

### Fixed
- Google Sign-In by updating package name to com.coachmaster.app
- Onboarding flow and team selection issues

## [1.0.0] - 2025-10-03

### Added
- Initial production release
- Player management with Italian football positions
- Training attendance tracking
- Match statistics wizard (7-step process)
- Match convocation management
- Dashboard with speed dial FAB
- Notes system for players, trainings, and matches
- Firebase Authentication (Email + Google Sign-In)
- Cloud Firestore real-time data sync
- Firebase Storage for player images
- Firebase Analytics integration
- Image compression (~500KB, 9:16 ratio)
- Italian default locale with English support
- Material 3 dark theme with orange (#FFA700) accents
- Google Play Store ready (API 35)

### Features
- **Players**: Card-based UI with positions, hero-style cards, stats badges
- **Trainings**: Attendance tracking, bottom sheet forms, notes integration
- **Matches**: Multi-step statistics wizard, convocation management, detailed player stats
- **Dashboard**: Speed dial FAB, sliding statistics carousel, leaderboards by position
- **Notes**: Flexible system linked to players/trainings/matches with CRUD operations
- **Images**: Auto-compression, Firebase Storage with cleanup, PlayerImageService workflow
- **Localization**: Complete Italian/English support
- **Real-time Sync**: Firestore streams for automatic UI updates across devices
