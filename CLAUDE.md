# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview
CoachMaster is a modern Flutter sports team management application designed for coaches to manage players, training sessions, matches, and team statistics. Built with a professional dark theme and orange accent colors, featuring modern UI components and intuitive navigation. Currently uses local Hive storage with plans to migrate to Firebase.

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

### Dependencies
- `flutter pub get` - Install dependencies
- `flutter pub upgrade` - Upgrade dependencies

## Project Architecture

### Tech Stack
- **Framework**: Flutter 3.35.2+ with Dart
- **State Management**: Riverpod 2.5.1 for reactive state management
- **Navigation**: GoRouter 14.1.4 with StatefulShellRoute for persistent tabs
- **Local Storage**: Hive 2.2.3 with type adapters (migrating to Firebase)
- **UI Framework**: Material Design 3.0 with custom dark theme
- **Theme System**: Centralized AppColors class with orange (#FF7F00) primary color
- **Code Generation**: build_runner for Hive adapters and model serialization

### Code Structure

#### Core Architecture
- `lib/main.dart` - App entry point with Hive initialization and repository setup
- `lib/core/` - Core app components (theme, router, initialization)
  - `theme.dart` - Centralized dark theme with AppColors class
  - `router.dart` - Navigation configuration with all screen definitions
  - `repository_instances.dart` - Dependency injection for repositories
  - `app_initialization.dart` - Startup logic and Hive setup
- `lib/models/` - Data models with Hive type adapters (.g.dart files auto-generated)
- `lib/services/` - Repository pattern for data access
- `lib/features/` - Feature-based organization with screens and widgets
  - `dashboard/` - Home screen with speed dial FAB and widgets
  - `players/` - Enhanced player management with hero-style cards
  - `trainings/` - Training sessions with bottom sheet forms
  - `matches/` - Match management and statistics
  - `seasons/` - Season administration
  - `onboarding/` - User onboarding flow
- `lib/l10n/` - Internationalization and localization files

#### Data Layer
The app uses a repository pattern with Hive for local storage:
- Each model has a corresponding repository in `lib/services/`
- Models use Hive annotations and code generation
- All repositories follow the same pattern: `init()`, `getAll()`, `get(id)`, `add()`, `update()`, `delete()`

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
- **TrainingAttendance**: Attendance records for training sessions
- **MatchConvocation**: Player convocations for matches
- **MatchStatistic**: Individual player statistics per match

## Design System & UI Patterns

### Theme System
The app uses a centralized theme system in `lib/core/theme.dart`:
```dart
class AppColors {
  static const Color primary = Color(0xFFFF7F00); // Orange
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
```

#### Model Creation
Models use factory constructors for creation with auto-generated IDs:
```dart
Team.create(name: "Team Name", seasonId: seasonId)
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

## Current Features & Recent Improvements

### Dashboard Enhancements
- **Speed Dial FAB**: Expandable floating action button with 3 sub-actions (Add Player, Add Training, Add Match)
- **Team Statistics**: 2-column mobile-optimized grid with orange icons and compact spacing
- **Player Carousel**: Swipeable player cards showing 2 cards per view with dot pagination
- **Mobile Responsive**: Fixed overflow errors and optimized for mobile screens

### Enhanced Player Management
- **Hero-Style Player Cards**: Large background images (300px height) with overlay information
- **Orange Stats Badges**: Goals and assists displayed as floating badges on player images
- **Bottom Sheet Forms**: Modern draggable forms for adding/editing players instead of dialogs
- **Player Detail Redesign**: Stunning visual design with background images and stat overlays

### Modern UI Components
- **Bottom Sheets**: All forms now use `DraggableScrollableSheet` with handle bars
- **Consistent Headers**: Orange icons with screen names across all AppBars
- **Dark Theme**: Professional dark theme with orange (#FF7F00) accent colors
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

### Performance Considerations
- Use `ValueKey` for images to force rebuilds when photos change
- Implement proper dispose methods for controllers (PageController, etc.)
- Use `Expanded` widgets to prevent overflow in flexible layouts
- Optimize image loading with proper error handling

### Future Migration Notes
The project documentation indicates a planned migration to Firebase for backend services. Current local Hive storage will be replaced with Firestore and offline-first architecture.