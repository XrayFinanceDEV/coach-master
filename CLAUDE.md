# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview
CoachMaster is a modern Flutter sports team management application designed for coaches to manage players, training sessions, matches, and team statistics. Built with a professional dark theme and orange accent colors, featuring modern UI components and intuitive navigation. Features Firebase Authentication with Google Sign-In integration and hybrid Hive/Firebase data storage.

## Development Commands

### Flutter Development
- `flutter run` - Run the app in development mode
- `flutter analyze` - Static analysis of Dart code
- `flutter test` - Run unit and widget tests
- `flutter build apk` - Build Android APK
- `flutter build ios` - Build iOS app
- `flutter build web` - Build web version

### Code Generation
- `flutter packages pub run build_runner build` - Generate Hive adapters and other code
- `flutter packages pub run build_runner watch` - Watch for changes and auto-generate code

### Localization
- `flutter gen-l10n` - Generate localization files after modifying ARB files

### Dependencies
- `flutter pub get` - Install dependencies
- `flutter pub upgrade` - Upgrade dependencies

## Project Architecture

### Tech Stack
- **Framework**: Flutter 3.35.2+ with Dart
- **State Management**: Riverpod 2.5.1 for reactive state management
- **Navigation**: GoRouter 14.1.4 with StatefulShellRoute for persistent tabs
- **Authentication**: Firebase Auth 6.0.2 with Google Sign-In 6.2.1 integration
- **Storage**: Hybrid Hive 2.2.3 (local) + Cloud Firestore 6.0.1 (cloud sync)
- **File Storage**: Firebase Storage 13.0.1 with automatic image compression
- **Analytics**: Firebase Analytics 12.0.1 for user behavior and feature tracking
- **Image Processing**: flutter_image_compress 2.3.0 + image 4.2.0 for optimization
- **UI Framework**: Material Design 3.0 with custom dark theme
- **Theme System**: Centralized AppColors class with orange (#FFA700) primary color
- **Code Generation**: build_runner for Hive adapters and model serialization

### Code Structure

#### Core Architecture
- `lib/main.dart` - App entry point with Firebase + Hive initialization and repository setup
- `lib/firebase_options.dart` - Firebase configuration for all platforms (web, Android, iOS, macOS)
- `lib/core/` - Core app components (theme, router, initialization, auth)
  - `theme.dart` - Centralized dark theme with AppColors class
  - `router.dart` - Navigation configuration with all screen definitions
  - `repository_instances.dart` - Dependency injection for repositories
  - `app_initialization.dart` - Startup logic and Hive setup
  - `auth_providers.dart` - Legacy auth provider (fallback for local auth)
  - `firebase_auth_providers.dart` - Firebase authentication state management
- `lib/models/` - Data models with Hive type adapters (.g.dart files auto-generated)
- `lib/services/` - Repository pattern and authentication services
  - `firebase_auth_service.dart` - Firebase Auth + Google Sign-In implementation with analytics
  - `analytics_service.dart` - Firebase Analytics tracking for user behavior and features
  - `sync_manager.dart` - Hybrid local/cloud data synchronization
  - `*_sync_repository.dart` - Cloud-enabled repositories with analytics integration
  - `player_image_service.dart` - Complete player photo workflow (pick→compress→upload)
  - `image_compression_service.dart` - Smart image compression to ~500KB with 9:16 ratio
  - `firebase_storage_service.dart` - Cloud file storage with automatic cleanup
- `lib/features/` - Feature-based organization with screens and widgets
  - `auth/` - Login and authentication screens with Google Sign-In
  - `dashboard/` - Home screen with speed dial FAB and widgets
  - `players/` - Enhanced player management with hero-style cards
  - `trainings/` - Training sessions with bottom sheet forms
  - `matches/` - Match management and statistics
  - `seasons/` - Season administration
  - `onboarding/` - User onboarding flow
- `lib/l10n/` - Internationalization and localization files

#### Data Layer
The app uses a hybrid local/cloud storage architecture:
- **Local Storage**: Hive 2.2.3 for offline-first data persistence
- **Cloud Storage**: Firebase Firestore for data synchronization across devices
- **Repository Pattern**: Each model has corresponding repositories in `lib/services/`
  - Base repositories: Local Hive-based data access
  - Sync repositories: Cloud-enabled with automatic sync capabilities
- **Models**: Use Hive annotations and code generation (.g.dart files)
- **Standard Interface**: All repositories follow the pattern: `init()`, `getAll()`, `get(id)`, `add()`, `update()`, `delete()`

#### Navigation Structure
Uses GoRouter with StatefulShellRoute for persistent bottom navigation:
- 5 main tabs: Home, Players, Trainings, Matches, Settings
- Nested routing for detail screens
- Tab persistence when navigating between sections

### Key Models
- **Season**: Sports seasons (July-June format)
- **Team**: Teams within seasons
- **Player**: Individual players with photos and statistics
- **Training**: Training sessions with attendance tracking
- **Match**: Matches with convocations and statistics
- **Note**: Flexible note system for players and trainings with CRUD operations
- **TrainingAttendance**: Attendance records for training sessions
- **MatchConvocation**: Player convocations for matches
- **MatchStatistic**: Individual player statistics per match

## Design System & UI Patterns

### Theme System
The app uses a centralized theme system in `lib/core/theme.dart`:
```dart
class AppColors {
  static const Color primary = Color(0xFFFFA700); // Orange
  static const Color secondary = Color(0xFF607D8B); // Blue Grey
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);
}

final appTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  colorScheme: const ColorScheme.dark(
    primary: AppColors.primary,
    secondary: AppColors.secondary,
    surface: AppColors.darkSurface,
  ),
  // ... other theme properties
);
```

### Modern UI Components

#### Bottom Sheets (Preferred over Dialogs)
Use `showModalBottomSheet` with `DraggableScrollableSheet` for forms:
```dart
showModalBottomSheet(
  context: context,
  isScrollControlled: true,
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
  ),
  builder: (context) => DraggableScrollableSheet(
    initialChildSize: 0.9,
    maxChildSize: 0.95,
    minChildSize: 0.5,
    expand: false,
    builder: (context, scrollController) => Container(
      padding: EdgeInsets.only(
        left: 16, right: 16, top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: // Form content with handle bar
    ),
  ),
);
```

#### Carousel Components
Use `PageView.builder` with dot indicators for card carousels:
```dart
PageView.builder(
  controller: pageController,
  onPageChanged: (page) => setState(() => currentPage = page),
  itemCount: (items.length / 2).ceil(),
  itemBuilder: (context, pageIndex) {
    // Show 2 cards per page
    final startIndex = pageIndex * 2;
    final pageItems = items.sublist(startIndex, math.min(startIndex + 2, items.length));
    return Row(
      children: pageItems.map((item) => Expanded(child: ItemCard(item))).toList(),
    );
  },
);
```

#### Consistent Headers
All screens should use orange icon + screen name pattern:
```dart
AppBar(
  title: Row(
    children: [
      Icon(Icons.screen_icon, color: Theme.of(context).colorScheme.primary),
      const SizedBox(width: 8),
      const Text('Screen Name'),
    ],
  ),
),
```

#### Speed Dial FAB
Expandable floating action button with sub-actions:
```dart
Column(
  mainAxisSize: MainAxisSize.min,
  children: [
    if (isSpeedDialOpen) ...subActionButtons,
    FloatingActionButton(
      onPressed: () => setState(() => isSpeedDialOpen = !isSpeedDialOpen),
      child: AnimatedRotation(
        turns: isSpeedDialOpen ? 0.125 : 0,
        duration: const Duration(milliseconds: 300),
        child: Icon(isSpeedDialOpen ? Icons.close : Icons.add),
      ),
    ),
  ],
);
```

### Development Patterns

#### Repository Pattern
All data access goes through repository classes:
```dart
// Example repository usage
final teamRepo = ref.watch(teamRepositoryProvider);
final teams = teamRepo.getTeamsForSeason(seasonId);

// Notes repository usage
final noteRepo = ref.watch(noteRepositoryProvider);
final notes = noteRepo.getNotesForPlayer(playerId);
```

#### Model Creation
Models use factory constructors for creation with auto-generated IDs:
```dart
Team.create(name: "Team Name", seasonId: seasonId)
Note.create(content: "Note content", type: NoteType.player)
```

#### State Management with Riverpod
Use Consumer widgets for reactive UI updates:
```dart
class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(dataProvider);
    return // UI that rebuilds when data changes
  }
}
```

#### Notes System Integration
When implementing notes functionality in new screens:
```dart
// Get notes for entity
final noteRepository = ref.watch(noteRepositoryProvider);
final notes = noteRepository.getNotesForLinkedItem(entityId, linkedType: 'entity_type');

// Create note
await noteRepository.createQuickNote(
  content: content,
  type: NoteType.entity,
  linkedId: entityId,
  linkedType: 'entity_type',
);
```

#### Code Generation
The project uses build_runner for generating:
- Hive type adapters (`.g.dart` files)
- Other code generation as needed

Run `flutter packages pub run build_runner build --delete-conflicting-outputs` after modifying model annotations.

### File Organization
- Follow the existing feature-based structure in `lib/features/`
- Each feature has list and detail screens
- Keep models in `lib/models/` with corresponding repositories in `lib/services/`
- Core utilities and shared components in `lib/core/`

## Data Synchronization Architecture

### Core Sync Patterns
The app uses a sophisticated synchronization system to ensure UI consistency across all screens when data changes:

#### Central Refresh Counter System
```dart
// Core counter provider in repository_instances.dart
final refreshCounterProvider = StateProvider<int>((ref) => 0);

// All reactive providers watch this counter
final playerListProvider = Provider<List<Player>>((ref) {
  final repo = ref.watch(playerRepositoryProvider);
  ref.watch(refreshCounterProvider); // Force rebuild when counter changes
  return repo.getPlayers();
});
```

#### Screen-Level Reactivity
All list screens watch the refresh counter for automatic rebuilds:
```dart
@override
Widget build(BuildContext context) {
  final counter = ref.watch(refreshCounterProvider); // Triggers rebuild
  final items = ref.watch(itemListProvider); // Gets fresh data
  // ... build UI
}
```

### Sync Operation Patterns

#### Add Operations
**Pattern**: `Repository.add()` → `refreshCounter++` → `onSaved callback`
```dart
final newItem = Item.create(/*...*/);
await repository.addItem(newItem);
ref.read(refreshCounterProvider.notifier).state++; // Increment counter
Navigator.pop(); // Close form
ScaffoldMessenger.showSnackBar(/*success message*/);
```

#### Edit Operations  
**Pattern**: `Repository.update()` → `refreshCounter++` → `setState()` → `provider invalidation`
```dart
onSaved: () {
  final currentCounter = ref.read(refreshCounterProvider.notifier).state;
  ref.read(refreshCounterProvider.notifier).state++;
  print('🟢 Refresh counter incremented from $currentCounter to $newCounter');
  
  ref.invalidate(repositoryProvider); // Optional provider invalidation
  if (mounted) {
    setState(() {}); // Force local rebuild
  }
},
```

#### Delete Operations
**Pattern**: `Repository.delete()` → `cleanup related data` → `provider invalidation` → `refreshCounter++` → `navigation`
```dart
// Delete main entity
await repository.deleteItem(item.id);

// Clean up related data across repositories
await relatedRepository1.deleteRelatedData(item.id);
await relatedRepository2.deleteRelatedData(item.id);

// Invalidate affected providers
ref.invalidate(repositoryProvider);
ref.invalidate(relatedRepositoryProvider);

if (context.mounted) {
  context.pop(); // Close dialog
  context.go('/items'); // Navigate back to list
}
```

### Sync Best Practices
- **Refresh Counter is Central**: Main synchronization mechanism across all screens
- **Provider Invalidation**: Used for immediate updates in complex operations
- **Cleanup Pattern**: Delete operations always clean related data across repositories
- **Navigation After Delete**: Detail screens navigate to list screens after successful deletion
- **Debug Logging**: Extensive logging with colored prefixes (🟢🔵🟦) for tracking sync operations
- **Mounted Checks**: Always verify `mounted` before calling `setState()` or navigation
- **Async Operations**: All repository operations use proper `async`/`await` patterns

### Settings Screen Architecture (Latest Update)
- **Fixed Season System**: Default "2025-26" season, non-editable with preview of "2026-27 (Coming Soon)"
- **Team Selector Integration**: Dropdown combines existing teams with "Create New Team" option
- **Streamlined Management**: Removed redundant "Manage Teams" button, simplified to team selection/creation only
- **Auto-Creation Logic**: Automatically creates 2025-26 season if it doesn't exist

## Current Features & Recent Improvements

### Production Ready & Google Play Store (Latest)
- **Android API 35 Compliance**: Updated target SDK for Google Play Store requirements
  - Compile SDK: API 36 (latest Android SDK for plugin compatibility)
  - Target SDK: API 35 (Android 15 - required by Google Play Store)
  - Min SDK: API 26 (Firebase compatibility and reasonable device support)
  - Build Tools: Gradle 8.12 with Kotlin support
- **Firebase Configuration Updates**: Updated SHA-1 certificates for production authentication
  - Release SHA-1: `03:97:AF:BC:45:C4:BE:CE:CB:9A:9A:44:24:B2:32:2C:06:2D:89:C5`
  - Debug SHA-1: `A1:C4:C9:A5:C7:D6:4A:06:A0:79:4D:B9:2D:10:38:E1:08:DB:16:F6`
  - Updated `google-services.json` with correct certificate hashes
- **Player Image System Fixes**: Enhanced cross-platform image handling
  - Fixed Firebase Storage URL support on mobile platforms
  - Enhanced `ImageUtils.getSafeImageProvider()` for robust image loading
  - Updated `PlayerImageService.getImageProvider()` with proper error handling
  - Improved image display consistency across player cards and detail screens
- **Release Build Optimization**: Ready for Google Play Console submission
  - Signed AAB files with proper keystore configuration
  - Tree-shaken fonts (99%+ size reduction)
  - Plugin compatibility with latest Android SDK

### Translation System Consistency
- **Complete Screen Localization**: All major user-facing screens now have complete Italian/English translations
  - Dashboard loading states and error messages fully localized
  - Players screen empty states and filter labels properly translated
  - Position filtering system uses centralized ARB keys instead of hardcoded logic
  - Eliminated conditional language checking in favor of AppLocalizations pattern
- **Enhanced ARB Management**: Added comprehensive translation keys for all UI elements
  - Loading messages: `loadingDashboard`, `settingUpTeams`, `loadingTeamData`
  - User interaction feedback: `pleaseSelectTeamFirst`, `noPlayersFound`, `addPlayersToTeam`
  - Position system: `allPlayers`, `attacco`, `centrocampo`, `difesa` with proper pluralization
- **Code Quality Improvements**: Replaced hardcoded localization logic with proper ARB lookups
  - Consistent `AppLocalizations.of(context)!` pattern throughout codebase
  - No compilation errors after translation updates
  - Centralized translation management for maintainability

### Image Management System (Latest)
- **Automatic Image Compression**: Smart compression to ~500KB while maintaining quality
  - Target size: ~500KB for optimal Firebase Storage usage
  - Aspect ratio optimization: 9:16 ratio (720x1280 or 1080x1920)
  - Iterative quality reduction (95% → 10%) to hit target size
- **Firebase Storage Integration**: Seamless cloud storage with automatic fallbacks
  - User-specific storage paths: `users/{userId}/players/{playerId}/profile_{timestamp}.jpg`
  - Automatic cleanup of old images (keeps latest 3 per player)
  - Progress monitoring during uploads with user feedback
- **Complete Player Photo Workflow**: Integrated pick → compress → upload → sync pipeline
  - `PlayerImageService.pickAndProcessPlayerImage()` - One-call solution
  - Platform-aware image handling (web base64, mobile file paths)
  - Automatic fallback to local storage when offline or unauthenticated
- **Enhanced Player Forms**: Updated photo selection with compression integration
  - Real-time processing feedback with loading indicators
  - Smart error handling with user-friendly messages
  - Seamless integration with existing player management

### Match Management System (Latest)
- **Match Status Form**: Multi-step wizard for match statistics with 6-7 steps
  - Step 1: Match result (goals for/against)
  - Step 2: Goals detail by player with position-based grouping (Attack → Midfield → Defense)
  - Step 3: Assists tracking with validation (cannot exceed goals)
  - Step 4: Cards management with limits (max 2 yellow, max 1 red per player)
  - Step 5: Playing time choice (optional detailed tracking)
  - Step 6: Playing time sliders (if enabled)
  - Step 7: Player ratings (1-10 scale with 0.5 increments, always-visible sliders)
- **Convocation Management**: Bottom sheet for selecting match participants with green highlight
- **Statistics Persistence**: Load existing data when editing match status (no more starting from 0)
- **Image Handling**: Robust player image display across all match forms with platform detection
- **UI Consistency**: Same image handling pattern as Players screen with proper fallbacks

### Dashboard & Match Screen Improvements (Latest)
- **Comprehensive Team Statistics**: Enhanced dashboard statistics with 8 key metrics
  - Row 1: Matches, Wins, Draws, Losses
  - Row 2: Goals For, Goals Against, Goal Difference, Win Rate
  - Moved from matches screen to dashboard for better overview
- **Matches Screen Redesign**: Cleaner layout with team stats removed
  - Add Match button moved to bottom of matches list (like Add Training pattern)
  - Removed duplicate statistics display
  - Focused on match list and management
- **Redesigned Leaderboards**: Complete overhaul of top 5 players section
  - Single full-width cards instead of 2x2 grid layout
  - Up to 5 player rows per category (Attack, Midfield, Defense)
  - Match-steps style player rows with avatars and stat badges
  - Position-based ranking with gold/silver/bronze badges
  - Clickable player navigation to detail screens

### Comprehensive Notes System (Enhanced)
- **Note Model**: Dedicated Note model with Hive type adapters and full CRUD operations
- **Repository Pattern**: NoteRepository with methods for player, training, and match notes
- **Bottom Sheet Input Forms**: Modern draggable forms for adding/editing/deleting notes
- **Notes Cards**: Professional UI cards with popup menus for note management
- **Cross-Feature Integration**: Notes work consistently across player, training, and match screens
- **Match Notes Support**: Complete notes system integration in match detail screens
- **Real-Time Updates**: Immediate UI refresh after note operations

### Training Management Modernization
- **Bottom Sheet Forms**: Replaced all training dialogs with modern bottom sheet forms
- **Single-Team Workflow**: Removed team selection field - coach works with one selected team
- **TrainingFormBottomSheet**: Shared widget for both add and edit training operations
- **No Coach Notes Field**: Legacy coach notes removed in favor of dedicated Notes system
- **Consistent Styling**: Material Design 3 with OutlinedButton/FilledButton pattern
- **Keyboard Handling**: Proper form validation and on-screen keyboard support

### Enhanced Player Detail Screen
- **Notes Section**: Complete notes management with add/edit/delete functionality
- **Modern Note Cards**: Elevated cards with timestamps and popup menus
- **Note Item UI**: Orange-themed containers with proper spacing and typography
- **Bottom Sheet Input**: Consistent note input forms with handle bars and validation

### Enhanced Training Detail Screen
- **Replicated Notes System**: Same notes functionality as player detail screen
- **Modern Edit Forms**: Training editing now uses bottom sheet instead of dialog
- **Consistent UI**: Same note management patterns across all screens
- **Data Preservation**: Existing coach notes preserved during form updates

### Critical Bug Fixes & System Improvements (Latest)
- **Player Stats Update Fix**: Fixed missing player statistics aggregation after match completion
  - Added automatic calculation of total goals, assists, and average ratings
  - Updates all team players' stats when matches are completed
  - Resolved empty leaderboards issue despite completed matches
- **Position Categorization Enhancement**: Improved multi-step match form player grouping
  - Always display all 4 categories (Attack, Midfield, Defense, Other) regardless of player distribution
  - Added comprehensive Italian position term support (attaccante, centrocampista, difensore, portiere)
  - Enhanced position matching logic for bilingual team management
  - Empty categories show helpful "No players in this category" message
- **Icon Consistency**: Standardized assist icons to use `Icons.gps_fixed` (target icon) across all screens
- **Convocation Memory Fix**: Fixed convocation management to remember previously selected players
- **Italian Localization**: Improved "Top Scorers" translation from "Migliori Marcatori" to "Migliori Cannonieri"

### UI/UX Improvements & Android Optimizations (Latest)
- **Match Form Score Layout**: Fixed Android multi-step form score input - changed from horizontal (left/right) to vertical (+/-) layout for better mobile space optimization
- **Player Filter Buttons**: Redesigned 4-button layout with icons above text instead of beside for better mobile screen real estate
- **Main Theme Color Update**: Updated primary accent color from #FF7F00 to #FFA700 for improved visual contrast and modern appearance
- **Convocation Count Bug Fix**: Fixed Android issue where convocation count was stuck at 2 players regardless of actual selection
- **Match Detail Screen Refresh**: Added proper refresh counter watching to ensure convocation changes are reflected immediately across all screens

### Comprehensive Translation System (Latest)
- **Complete Match Screen Localization**: Fully translated matches main screen including:
  - App bar title, buttons, tooltips
  - Status badges (Scheduled/Live/Completed)
  - Match cards ("X convocated", "Stats saved")
  - Empty state messages
  - Popup menus and delete dialogs
- **Match Form Translation**: Complete localization of Add/Edit Match bottom sheet forms:
  - Form titles (Add Match/Edit Match)
  - All form fields (Opponent Team, Match Date, Location, Match Type)
  - Home/Away toggles
  - Action buttons and success messages
  - Validation error messages
- **Multi-step Form Localization**: Fixed untranslated text in match statistics form:
  - Step 1: "Goals For/Against" now properly localized
  - Steps 2-3: Position categories (Attack/Midfield/Defense) now use localized names
- **Enhanced ARB Files**: Added comprehensive translation keys for:
  - Match management terms
  - Form validation messages  
  - Success/error notifications
  - UI component labels

### Dashboard Enhancements
- **Speed Dial FAB**: Expandable floating action button with 3 sub-actions (Add Player, Add Training, Add Match)
- **Enhanced Team Statistics**: 2-row, 4-column layout with comprehensive match and team data
- **Player Carousel**: Swipeable player cards showing 2 cards per view with dot pagination
- **Mobile Responsive**: Fixed overflow errors and optimized for mobile screens

### Enhanced Player Management (Latest Update)
- **Card-Based Player Screen**: Complete redesign with 2 players per row in hero-style cards
- **Italian Football Terminology**: Professional position organization with authentic Italian terms
- **Position Filtering System**: Smart filter buttons (Tutti/Attacco/Centrocampo/Difesa) for quick navigation
- **Logical Football Organization**: Players grouped by position (Attacco → Centro Campo → Difesa)
- **Bilingual Support**: Dynamic Italian/English labels based on app language settings
- **No "Other" Categories**: All players properly categorized into the three main football sections
- **Position Hierarchy Sorting**: Players within each section ordered by football importance
- **Hero-Style Player Cards**: Large background images (200px height) with overlay information
- **Orange Stats Badges**: Goals and assists displayed as floating badges on player images
- **Bottom Sheet Forms**: Modern draggable forms with organized position dropdowns
- **Player Detail Redesign**: Stunning visual design with background images and stat overlays
- **Speed Dial Integration**: Quick player creation from dashboard with automatic navigation

### Modern UI Components
- **Bottom Sheets**: All forms now use `DraggableScrollableSheet` with handle bars
- **Consistent Headers**: Orange icons with screen names across all AppBars
- **Dark Theme**: Professional dark theme with orange (#FFA700) accent colors
- **Card-Based Design**: Elevated cards with proper spacing and rounded corners

### Settings & Internationalization
- **Language Selection**: Multi-language dropdown with flag emojis (5 languages supported)
- **Theme Controls**: Dark mode toggle and notification preferences (ready for implementation)
- **Team Management**: Comprehensive season and team administration tools

### Navigation & UX
- **Persistent Bottom Tabs**: 5 main sections with tab persistence
- **Improved Routing**: Enhanced GoRouter configuration with nested routes
- **Form Validation**: Better user feedback and error handling
- **Loading States**: Visual feedback for user interactions

## Italian Football Position System (Latest Feature)

### **Position Organization & Terminology**
The app now uses authentic Italian football terminology with professional position hierarchy:

**🔥 Attacco (Attack Section):**
1. **Attaccante** - Striker (main goalscorer)
2. **Trequartista** - Attacking Midfielder/False 9
3. **Ala Sinistra** - Left Winger
4. **Ala Destra** - Right Winger  
5. **Ala** - General Winger
6. **Punta** - Center Forward

**⚽ Centro Campo (Midfield Section):**
7. **Centrocampista Centrale** - Central Midfielder
8. **Centrocampista** - General Midfielder
9. **Mediano** - Defensive Midfielder/Holding Midfielder

**🛡️ Difesa (Defense Section):**
10. **Portiere** - Goalkeeper (listed first in defense)
11. **Difensore Centrale** - Center Back
12. **Difensore** - General Defender
13. **Terzino Sinistro** - Left Back
14. **Terzino Destro** - Right Back
15. **Terzino** - General Fullback
16. **Quinto** - Wing Back/Wingback

### **Bilingual Support Implementation**
```dart
String _getLocalizedFilterLabel(BuildContext context, String filterKey) {
  final currentLocale = Localizations.localeOf(context).languageCode;
  
  if (currentLocale == 'it') {
    switch (filterKey) {
      case 'all': return 'Tutti';
      case 'attack': return 'Attacco';
      case 'midfield': return 'Centrocampo';
      case 'defense': return 'Difesa';
    }
  } else {
    // English equivalents...
  }
}
```

### **Position Filtering & Organization**
- **Smart Filtering**: Filter buttons adapt to app language (Italian/English)
- **No "Other" Category**: All positions categorized into the three main football sections
- **Position Hierarchy**: Players within sections ordered by football importance
- **Dual Language Support**: English and Italian position terms recognized
- **Clean UI**: Professional football organization without confusion

## Development Guidelines

### Mobile-First Design
- Always test on mobile screen sizes first
- Use responsive padding and margins
- Implement overflow protection with proper constraints
- Prefer bottom sheets over dialogs for better mobile UX

### Consistency Rules
- Use `Theme.of(context).colorScheme.primary` for orange accents
- Include handle bars in bottom sheets for draggability
- Follow the orange icon + screen name pattern for all AppBars
- Use 8px spacing between icon and text in headers
- Implement proper keyboard padding with `MediaQuery.of(context).viewInsets.bottom`
- Use `OutlinedButton` for cancel actions and `FilledButton` for primary actions
- Always include popup menus for note management (edit/delete options)
- Preserve existing data when updating models (e.g., coachNotes field in Training)
- Use green highlights for selected/convocated items instead of orange to avoid UI confusion
- Position action buttons at bottom of lists (like Add Training/Add Match) for consistent UX
- Use `Icons.gps_fixed` (target icon) for all assist-related displays for consistency
- Always show all position categories in match forms regardless of player distribution

### Localization Best Practices
- **Always use AppLocalizations**: Never hardcode user-facing strings - use `AppLocalizations.of(context)!.keyName`
- **ARB File Management**: Add new keys to both `app_en.arb` and `app_it.arb` files
- **Regenerate After Changes**: Run `flutter gen-l10n` after modifying ARB files to update localization classes
- **Key Naming Convention**: Use descriptive camelCase names (e.g., `matchUpdatedSuccessfully`, `pleaseEnterOpponentTeam`)
- **Form Validation**: Localize all validation error messages for consistent user experience
- **Success/Error Messages**: Always provide localized feedback for user actions
- **Italian Football Terms**: Use authentic terminology (Casa/Trasferta, Squadra Avversaria, etc.)
- **Compilation Check**: Verify `flutter analyze` passes after adding new localization keys
- **No Hardcoded Logic**: Replace conditional language checking with centralized ARB key lookups
- **Consistent Pattern**: Use `AppLocalizations.of(context)!` throughout instead of manual locale detection
- **Translation Completeness**: All user-facing screens and forms must have complete Italian/English translations

### Match Statistics & Player Updates
**Critical Pattern**: Always update player aggregate statistics after match completion:
```dart
// After saving match statistics, update all team players' aggregate stats
final playerRepository = ref.read(playerRepositoryProvider);
final allMatchStats = statisticRepository.getStatistics();
final teamPlayers = playerRepository.getPlayersForTeam(teamId);
for (final player in teamPlayers) {
  await playerRepository.updatePlayerStatisticsFromMatchStats(player.id, allMatchStats);
}
```

### Multilingual Position Support
Support both English and Italian position terms in categorization logic:
```dart
// Example for forwards/attackers
final forwards = players.where((p) => 
    p.position.toLowerCase().contains('forward') || 
    p.position.toLowerCase().contains('striker') ||
    p.position.toLowerCase().contains('attacker') ||
    // Italian terms
    p.position.toLowerCase().contains('attaccante') ||
    p.position.toLowerCase().contains('centravanti')).toList();
```

### Performance Considerations
- Use `ValueKey` for images to force rebuilds when photos change: `key: ValueKey('${player.id}-${player.photoPath}')`
- Implement proper dispose methods for controllers (PageController, etc.)
- Use `Expanded` widgets to prevent overflow in flexible layouts
- Optimize image loading with proper error handling and platform detection
- Watch `playerImageUpdateProvider` for automatic rebuilds when player images change

### Image Management & Compression Guidelines

#### Using PlayerImageService
For all player photo operations, use the integrated PlayerImageService:
```dart
// Complete workflow: pick → compress → upload → return URL
final photoUrl = await PlayerImageService.pickAndProcessPlayerImage(playerId);

// Update player photo with cleanup
final updatedPlayer = await PlayerImageService.updatePlayerPhoto(player, newPhotoPath);

// Remove player photo with cleanup
final updatedPlayer = await PlayerImageService.removePlayerPhoto(player);

// Clean up all player images (when deleting player)
await PlayerImageService.cleanupPlayerImages(playerId);
```

#### Enhanced Image Display with ImageUtils
The core image handling has been improved for robust cross-platform support:
```dart
// Use centralized safe image provider
final imageProvider = ImageUtils.getSafeImageProvider(photoPath);

// Build safe image widgets
ImageUtils.buildSafeImage(
  imagePath: player.photoPath,
  fit: BoxFit.cover,
  errorWidget: fallbackWidget,
);

// Create player avatars with proper fallbacks
ImageUtils.buildPlayerAvatar(
  firstName: player.firstName,
  lastName: player.lastName,
  photoPath: player.photoPath,
  radius: 24,
);
```

#### Image Compression Configuration
The system automatically handles compression with these targets:
- **Target Size**: ~500KB for optimal Firebase Storage usage
- **Aspect Ratio**: 9:16 (720x1280 or 1080x1920)
- **Quality Range**: 95% → 10% (iterative reduction)
- **Format**: JPEG for maximum compatibility

#### Firebase Storage Integration
- **Path Structure**: `users/{userId}/players/{playerId}/profile_{timestamp}.jpg`
- **Automatic Cleanup**: Keeps latest 3 images per player
- **Fallback Strategy**: Local storage when offline or unauthenticated
- **Progress Feedback**: Built-in loading indicators and error handling
- **Cross-Platform URLs**: Supports Firebase Storage URLs, local files, and base64 data

### Image Display Best Practices
Use the enhanced ImageUtils for consistent and robust image display:
```dart
// Modern approach using ImageUtils (Recommended)
ImageUtils.buildPlayerAvatar(
  firstName: player.firstName,
  lastName: player.lastName,
  photoPath: player.photoPath,
  radius: 24,
  backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
  textColor: Theme.of(context).colorScheme.primary,
);

// For custom image containers
Container(
  decoration: BoxDecoration(
    image: DecorationImage(
      image: ImageUtils.getSafeImageProvider(player.photoPath!) ??
             AssetImage('assets/placeholder.png'),
      fit: BoxFit.cover,
    ),
  ),
);

// For safe image widgets with error handling
ImageUtils.buildSafeImage(
  imagePath: player.photoPath,
  width: 200,
  height: 200,
  fit: BoxFit.cover,
  errorWidget: Icon(Icons.person, size: 48),
);
```

## Architecture Decisions & Workflow

### Single-Team Workflow
CoachMaster is designed for coaches to work with one team at a time:
- **Team Selection**: Coaches select their active team in settings
- **No Mixed Data**: All operations (trainings, notes, etc.) apply to the selected team
- **Simplified Forms**: No team selection dropdowns in training/player forms
- **Context Awareness**: All screens automatically work with the currently selected team

### Notes System Architecture
The notes system is designed to be flexible and extensible:
- **Generic Model**: Note model can be linked to any entity (players, trainings, matches, etc.)
- **Type Safety**: NoteType enum defines supported note types
- **Consistent UI**: Same UI patterns for notes across all features
- **Repository Pattern**: Centralized data access through NoteRepository

## Firebase Authentication Integration

### Authentication Architecture
The app implements a hybrid authentication system with Firebase as the primary method:

#### Firebase Authentication Setup
- **Primary Auth**: Firebase Auth 6.0.2 with email/password and Google Sign-In
- **Google Sign-In**: Integrated across web, Android, and iOS platforms
- **Fallback**: Local authentication system maintained for backward compatibility
- **State Management**: Riverpod-based reactive authentication state

#### Authentication Flow
1. **Firebase-First**: Always attempts Firebase authentication first
2. **Google Sign-In**: Seamless OAuth integration with Firebase Auth
3. **Email/Password**: Traditional signup/login with Firebase
4. **Local Fallback**: Legacy system available if Firebase fails
5. **Auto-Sync**: User data synchronized to Firestore upon authentication

#### Key Components
- `lib/services/firebase_auth_service.dart` - Core Firebase Auth + Google Sign-In implementation
- `lib/core/firebase_auth_providers.dart` - Dedicated Firebase auth state management
- `lib/core/auth_providers.dart` - Hybrid auth provider with Firebase-first approach
- `lib/features/auth/login_screen.dart` - Modern login UI with Google Sign-In button

#### Web Configuration Requirements
For Google Sign-In on web, update the Web Client ID in `firebase_auth_service.dart`:
```dart
clientId: kIsWeb ? 'YOUR_WEB_CLIENT_ID.apps.googleusercontent.com' : null,
```
Get the Web Client ID from Firebase Console → Project Settings → Web SDK configuration.

#### Authentication State
- **Loading**: During authentication process
- **Authenticated**: Firebase user with sync capabilities  
- **Unauthenticated**: No authenticated user
- **Error**: Authentication failures with user-friendly messages

### Data Synchronization
The app now uses a hybrid storage approach:
- **Local-First**: Hive storage for offline capabilities
- **Cloud Sync**: Firestore synchronization for authenticated users
- **Automatic**: Background sync when user is authenticated
- **Offline Support**: Full app functionality without internet connection

## Firebase Analytics Integration

### Analytics Architecture
The app includes comprehensive Firebase Analytics tracking to monitor user behavior, feature usage, and app performance:

#### Analytics Setup
- **Firebase Analytics**: Version 12.0.1 integrated with existing Firebase project
- **Configuration**: Uses same `google-services.json` configuration as other Firebase services
- **Router Integration**: Automatic screen view tracking via `FirebaseAnalyticsObserver`
- **Cross-Platform**: Works seamlessly across web, Android, and iOS platforms

### Production Configuration
- **SHA-1 Certificates**: Updated for production authentication
  - Release Keystore SHA-1: `03:97:AF:BC:45:C4:BE:CE:CB:9A:9A:44:24:B2:32:2C:06:2D:89:C5`
  - Debug Keystore SHA-1: `A1:C4:C9:A5:C7:D6:4A:06:A0:79:4D:B9:2D:10:38:E1:08:DB:16:F6`
- **Google Services**: Updated `google-services.json` with correct certificate hashes
- **Android Build**: Configured for Google Play Store submission
  - Target SDK: API 35 (Android 15)
  - Compile SDK: API 36 (latest for plugin compatibility)
  - Signed AAB files ready for upload

#### Key Components
- `lib/services/analytics_service.dart` - Core analytics service with comprehensive event tracking
- `lib/core/analytics_providers.dart` - Riverpod providers for dependency injection
- `docs/FIREBASE_ANALYTICS_SETUP.md` - Complete setup and usage documentation

#### Tracked Events

**User Events:**
- Login/signup with method tracking (email, Google)
- User ID assignment for session tracking
- Language preference changes

**Team Management:**
- Team creation and season setup
- Settings configuration changes

**Player Management:**
- Player creation and updates
- Photo upload and management
- Player statistics tracking

**Training Events:**
- Training session creation
- Attendance tracking with participant counts
- Notes and coaching observations

**Match Events:**
- Match creation and scheduling
- Match completion with results
- Statistics saving with player participation
- Convocation management

**Feature Usage:**
- Screen navigation (automatic)
- Speed dial FAB usage
- Bottom sheet form interactions
- Search and filtering actions

**Error Tracking:**
- Sync failures and recovery
- Authentication errors
- Image processing failures
- General app errors with context

#### Analytics Integration Points

**Authentication Service:**
```dart
// Automatic tracking in firebase_auth_service.dart
await AnalyticsService.logLogin(method: 'email');
await AnalyticsService.setUserId(credential.user?.uid ?? '');
```

**Repository Level:**
```dart
// Example in player_sync_repository.dart
await addWithSync(player);
await AnalyticsService.logPlayerAdded();
```

**Screen Navigation:**
```dart
// Automatic via router configuration
observers: [AnalyticsService.observer]
```

#### Privacy and Data Handling
- **User ID Only**: No personally identifiable information logged
- **Aggregated Data**: All metrics are aggregated and anonymized
- **Debug Logging**: Console output in development for verification
- **GDPR Compliant**: Follows Firebase Analytics privacy guidelines

#### Usage Patterns
```dart
// Track feature usage
await AnalyticsService.logFeatureUsed(featureName: 'player_filter');

// Track custom events with parameters
await AnalyticsService.logMatchCompleted(
  goalsFor: 3,
  goalsAgainst: 1,
  result: 'win',
);

// Error tracking
await AnalyticsService.logError(
  errorType: 'sync_failure',
  errorMessage: 'Failed to sync player data',
);
```

#### Development Guidelines
- **Event Naming**: Use descriptive snake_case names for events
- **Parameter Limits**: Follow Firebase's parameter naming and count limits
- **Debug Mode**: All events log to console in development
- **User Properties**: Set relevant user properties for segmentation
- **Custom Dimensions**: Use parameters for additional context