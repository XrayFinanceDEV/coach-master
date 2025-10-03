# Changelog

All notable changes to CoachMaster will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
