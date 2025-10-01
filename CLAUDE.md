# CLAUDE.md

**Guidance for Claude Code when working with this repository.**

## Project Overview
CoachMaster - Flutter sports team management app for coaches. Dark theme with orange (#FFA700) accents, Firebase-only architecture (Auth + Firestore + Storage), Italian default locale.

## Quick Commands
```bash
flutter run                                                      # Run app
flutter analyze                                                  # Static analysis
flutter gen-l10n                                                 # Generate localizations
```

## Tech Stack
- **Core**: Flutter 3.35.2+, Dart
- **State**: Riverpod 2.5.1
- **Navigation**: GoRouter 14.1.4 (5 persistent tabs)
- **Auth**: Firebase Auth 6.0.2 + Google Sign-In 6.2.1
- **Storage**: Cloud Firestore 6.0.1 (Firestore-only, no Hive)
- **Files**: Firebase Storage 13.0.1
- **Analytics**: Firebase Analytics 12.0.1
- **Images**: flutter_image_compress 2.3.0 (~500KB target, 9:16 ratio)
- **Locale**: Italian default, full IT/EN support
- **UI**: Material 3 dark theme, orange (#FFA700) primary

## Code Structure
```
lib/
├── main.dart              # App entry, Firebase initialization
├── core/                  # Theme, router, providers, initialization
│   ├── firestore_repository_providers.dart  # Stream providers for real-time data
│   ├── selected_team_provider.dart          # Team selection with Firestore persistence
│   └── locale_provider.dart                 # Italian default locale
├── models/                # Data models (plain Dart classes, no Hive)
├── services/              # Firestore repositories, auth, analytics, image processing
│   ├── firestore_*_repository.dart          # All data repositories use Firestore
│   └── firestore_user_settings_repository.dart  # User preferences (selected team/season)
├── features/              # Feature-based screens (auth, dashboard, players, trainings, matches, seasons)
└── l10n/                  # Italian/English translations (ARB files)
```

**Key Models**: Season, Team, Player, Training, Match, Note, TrainingAttendance, MatchConvocation, MatchStatistic

**Repository Pattern**: All repos are Firestore-based with real-time streams. Pattern: `getTeam()`, `teamStream()`, `addTeam()`, `updateTeam()`, `deleteTeam()`.

## UI Patterns

### Key Components
- **Bottom Sheets**: Use `DraggableScrollableSheet` for all forms (not dialogs)
- **Carousels**: `PageView.builder` with dot pagination (2 cards/page, 280px height for 2x2 stats)
- **Headers**: Orange icon + 8px spacing + screen name in AppBar
- **Speed Dial FAB**: Expandable FAB with sub-actions (dashboard)
- **Theme**: `Theme.of(context).colorScheme.primary` for orange accents

### Development Patterns
- **State**: `ConsumerWidget` + `ref.watch(streamProvider)` for real-time reactive UI
- **Models**: Plain Dart classes with `copyWith()` methods (no Hive annotations)
- **Repos**: Access via `ref.watch(repositoryProvider)` for repository instance
- **Streams**: Use `ref.watch(streamProvider)` for real-time Firestore data
- **No Code Gen**: No build_runner needed (Hive removed)

## Data Synchronization

**Firebase Real-Time Streams**: All data uses Firestore streams for automatic real-time updates. UI rebuilds automatically when data changes.

**Stream Providers** (in `firestore_repository_providers.dart`):
- `teamsStreamProvider` - Real-time team list
- `playersForTeamStreamProvider(teamId)` - Players for specific team
- `matchesForTeamStreamProvider(teamId)` - Matches for specific team
- `trainingsForTeamStreamProvider(teamId)` - Trainings for specific team
- etc.

**CRUD Patterns**:
- **Add**: `await repo.addTeam(team)` → Firestore writes → streams update automatically
- **Edit**: `await repo.updateTeam(team)` → streams update automatically
- **Delete**: `await repo.deleteTeam(id)` → cleanup related data → streams update automatically

**No Manual Refresh**: Streams handle all updates automatically. No `refreshCounter`, no `setState()` needed for data changes.

**Critical**: Delete operations must clean up related data across all repositories (cascading deletes).

## Key Features
- **Players**: Card-based UI with Italian football positions (Attacco/Centrocampo/Difesa), hero-style cards, stats badges
- **Trainings**: Attendance tracking, bottom sheet forms, notes integration
- **Matches**: Multi-step statistics wizard (7 steps), convocation management, detailed player stats
- **Dashboard**: Speed dial FAB, sliding statistics carousel (2 pages, 2x2 grid), leaderboards by position
- **Notes**: Flexible system linked to players/trainings/matches with CRUD operations
- **Images**: Auto-compression to ~500KB (9:16 ratio), Firebase Storage with cleanup, `PlayerImageService` for workflow
- **Localization**: Complete Italian/English support via ARB files (`AppLocalizations.of(context)!`)
- **Production**: Google Play ready, API 35 target, flutter_launcher_icons with custom branding

## Italian Football Positions
**3 Categories**: Attacco (Attaccante, Trequartista, Ala, Punta) → Centro Campo (Centrocampista, Mediano) → Difesa (Portiere, Difensore, Terzino, Quinto)

**Bilingual**: Both Italian and English position terms supported in categorization logic. Filter buttons adapt to app language.

## Critical Guidelines

### UI Consistency
- **Colors**: Use `Theme.of(context).colorScheme.primary` for orange, green for selections (not orange)
- **Forms**: Bottom sheets with handle bars, proper keyboard padding, `OutlinedButton`/`FilledButton`
- **Icons**: `Icons.gps_fixed` for assists, orange icon + 8px + name in AppBar
- **Buttons**: Action buttons at bottom of lists (Add Training/Match pattern)

### Localization
- **Default Locale**: Italian (`it`) - set in `locale_provider.dart`
- **Never hardcode strings**: Always use `AppLocalizations.of(context)!.keyName`
- **After ARB changes**: Run `flutter gen-l10n` and verify with `flutter analyze`
- **Both languages**: Add keys to `app_en.arb` and `app_it.arb`
- **Synced Setting**: Language preference stored in Firestore (syncs across devices)

### Match Statistics
**Critical**: After match completion, update player aggregate stats:
```dart
final playerRepo = ref.read(playerRepositoryProvider);
final allMatchStats = statisticRepository.getStatistics();
for (final player in teamPlayers) {
  await playerRepo.updatePlayerStatisticsFromMatchStats(player.id, allMatchStats);
}
```

### Image Management
```dart
// Use PlayerImageService for all photo operations
await PlayerImageService.pickAndProcessPlayerImage(playerId);      // Pick + compress + upload
await PlayerImageService.updatePlayerPhoto(player, newPhotoPath);  // Update with cleanup
await PlayerImageService.cleanupPlayerImages(playerId);            // Delete all player images

// Use ImageUtils for display
ImageUtils.buildPlayerAvatar(firstName, lastName, photoPath, radius: 24);
ImageUtils.getSafeImageProvider(photoPath);  // Handles Firebase URLs, local files, base64
```

### Performance
- Use `ValueKey('${player.id}-${player.photoPath}')` for images
- Watch `playerImageUpdateProvider` for image rebuilds
- Dispose controllers (PageController, etc.)

## Architecture Notes

### Single-Team Workflow
Coach works with one selected team. No team dropdowns in forms. All operations apply to currently selected team.

**Team Selection**: Stored in Firestore at `/users/{userId}/selectedTeamId`. Syncs across devices automatically. Auto-selects first available team on login if none selected.

### Notes System
Generic `Note` model links to any entity (players/trainings/matches). `NoteRepository` provides centralized access.

### Firebase Integration (Firestore-Only Architecture)
- **Auth**: Firebase Auth (email/Google Sign-In). No local fallback.
- **Storage**: Cloud Firestore only. Real-time sync, offline caching built-in.
- **Analytics**: Firebase Analytics via `AnalyticsService`
- **Images**: Firebase Storage with auto-cleanup (keeps latest 3). Path: `users/{userId}/players/{playerId}/profile_{timestamp}.jpg`
- **User Settings**: Stored at `/users/{userId}` (selected team/season synced across devices)
- **Security Rules**: User can only access their own data at `/users/{userId}/**`

**Migration Complete**: All Hive code removed. App is 100% Firebase-based.

### Production Config
- **Android**: Target SDK 35, Compile SDK 36, Min SDK 26
- **SHA-1**: Release `03:97:AF:...`, Debug `A1:C4:C9:...` (see `google-services.json`)
- **Icons**: flutter_launcher_icons with `docs/logo_coach_master.png`