# CoachMaster ⚽

A modern, comprehensive Flutter sports team management application designed for coaches to efficiently manage players, training sessions, matches, and team statistics. Built with a beautiful dark theme and orange accent colors, featuring intuitive navigation and powerful management tools.

## ✨ Key Features

### 🏠 Dashboard & Home
- **Modern Speed Dial FAB**: Quick access to add players, trainings, and matches
- **Team Statistics Cards**: 2-column mobile-optimized stats display
- **Player Carousel**: Swipeable player cards with dots indicator (2 cards per view)
- **Season/Team Management**: Streamlined team and season selection
- **Responsive Design**: Mobile-first with overflow protection

### 🔥 Firebase Integration
- **Authentication**: Google Sign-In with Firebase Auth 6.0.2
- **Cloud Storage**: Firebase Firestore for data synchronization
- **File Storage**: Firebase Storage with automatic image compression
- **Analytics**: Firebase Analytics for user behavior tracking
- **Hybrid Architecture**: Local-first with cloud sync capabilities

### 👥 Enhanced Player Management  
- **Card-Based Layout**: Hero-style player cards (2 per row) with professional football imagery
- **Position Filtering**: Smart filter buttons (All/Attack/Midfield/Defense) with Italian terminology
- **Football Organization**: Logical position grouping (Attacco → Centro Campo → Difesa)
- **Bilingual Support**: Dynamic Italian/English labels based on app language settings
- **Professional Position Terms**: Authentic Italian football terminology (Attaccante, Trequartista, etc.)
- **Orange Stats Badges**: Goals and assists displayed as floating overlay badges
- **Advanced Player Profiles**: Complete information with stunning visual design
- **Bottom Sheet Forms**: Modern, draggable forms with organized position dropdowns
- **Enhanced Image Management**: Firebase Storage integration with automatic compression
- **Cross-Platform Photos**: Web and mobile image support with robust error handling
- **Statistics Tracking**: Goals, assists, cards, minutes played with position-based analysis

### 🏃 Training Management
- **Bottom Sheet Interface**: Modern form design for adding training sessions
- **Session Organization**: Date, time, location, and objectives tracking
- **Attendance System**: Real-time attendance with player photos
- **Interactive UI**: Easy-to-use switches and controls

### ⚽ Match Management
- **Match Scheduling**: Organize matches and convocations
- **Player Statistics**: Track individual performance per match  
- **Team Performance**: Comprehensive team analytics

### ⚙️ Settings & Preferences
- **Language Selection**: Bilingual support (English, Italian) with automatic UI translation
- **Dynamic Labels**: Filter buttons and sections adapt to selected language
- **Theme Preferences**: Dark mode toggle (ready for implementation)
- **Notifications**: Match and training reminder controls
- **Team Management**: Season and team administration tools

## 🎨 Design System

### Theme & Branding
- **Dark Theme**: Professional dark UI throughout the application
- **Orange Accents**: Consistent orange (#FFA700) primary color system
- **Material 3**: Modern Material Design 3.0 components and styling
- **Consistent Headers**: Orange icons + screen names across all screens

### User Experience
- **Bottom Sheets**: Modern, draggable forms replacing traditional dialogs
- **Card-Based Design**: Clean card layouts with proper elevation and spacing
- **Mobile Optimized**: Responsive design preventing overflow errors
- **Intuitive Navigation**: Persistent bottom navigation with tab icons

## 📱 Image Management System

### Firebase Storage Integration
- **Cloud Storage**: Firebase Storage for image hosting and synchronization
- **Automatic Compression**: Smart compression to ~500KB while maintaining quality
- **Aspect Ratio Optimization**: 9:16 ratio (720x1280 or 1080x1920)
- **User-Specific Paths**: `users/{userId}/players/{playerId}/profile_{timestamp}.jpg`
- **Automatic Cleanup**: Keeps latest 3 images per player

### Supported Formats
- **JPEG/JPG**: Standard photo format with compression
- **PNG**: With transparency support
- **WEBP**: Modern web format

### Features
- **Smart Compression**: Target size ~500KB for optimal Firebase Storage usage
- **Cross-Platform**: Works on web, mobile, and desktop
- **Real-time Preview**: Immediate photo preview in forms
- **Fallback Strategy**: Local storage when offline or unauthenticated
- **Progress Feedback**: Loading indicators and error handling

### Technical Implementation
- **Web**: Base64 data URLs and Firebase Storage URLs
- **Mobile/Desktop**: Firebase Storage URLs and local file fallbacks
- **Iterative Compression**: Quality reduction (95% → 10%) to hit target size
- **Platform Detection**: Automatic handling of different image types
- **Error Recovery**: Graceful fallback with user-friendly messages

## 🏗️ Architecture

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

### Android Configuration
- **Compile SDK**: API 36 (latest Android SDK for plugin compatibility)
- **Target SDK**: API 35 (Android 15 - required by Google Play Store)
- **Min SDK**: API 26 (Firebase compatibility and reasonable device support)
- **Build Tools**: Gradle 8.12 with Kotlin support

### Modern UI Components
- **DraggableScrollableSheet**: For bottom sheet forms
- **PageView**: Carousel components with dot indicators
- **AnimatedContainer**: Smooth transitions and animations
- **Stack & Positioned**: Complex overlay layouts
- **Hero Widgets**: Seamless navigation transitions

### Code Structure
```
lib/
├── core/                    # Core app components
│   ├── app_initialization.dart  # App startup and initialization
│   ├── repository_instances.dart # Dependency injection
│   ├── router.dart             # Navigation and screen definitions
│   ├── theme.dart             # Dark theme with orange accents
│   └── locale_provider.dart   # Internationalization support
├── features/                # Feature-based organization
│   ├── dashboard/          # Home screen with speed dial FAB
│   │   └── widgets/       # Reusable dashboard components
│   ├── players/           # Enhanced player management
│   ├── trainings/         # Training session management
│   ├── matches/           # Match and statistics management
│   ├── seasons/           # Season administration
│   ├── onboarding/        # User onboarding flow
│   └── training_attendances/ # Attendance tracking
├── models/                 # Data models with Hive adapters
├── services/              # Repository pattern for data access
└── l10n/                  # Localization files
```

### Design Patterns
- **Repository Pattern**: Clean data access abstraction
- **Consumer Pattern**: Reactive UI updates with Riverpod
- **Feature-First**: Organized by business functionality
- **Component Architecture**: Reusable UI components
- **Theme System**: Centralized styling and branding

## Development

### Prerequisites
- Flutter 3.x
- Dart SDK
- Android Studio / VS Code
- Device or emulator

### Setup
```bash
# Clone the repository
git clone <repository-url>

# Install dependencies
flutter pub get

# Generate code (for Hive adapters)
flutter packages pub run build_runner build

# Generate localization files
flutter gen-l10n

# Run the app
flutter run
```

### Development Commands
- `flutter run` - Run in development mode
- `flutter analyze` - Static analysis and linting
- `flutter test` - Run unit and widget tests
- `flutter build apk` - Build Android APK
- `flutter build ios` - Build iOS app
- `flutter build web` - Build web version
- `flutter gen-l10n` - Generate localization files after ARB changes

### Code Generation
Run after modifying model annotations or translations:
```bash
# For Hive adapters
flutter packages pub run build_runner build --delete-conflicting-outputs
flutter packages pub run build_runner watch  # For continuous generation

# For localization after ARB file changes
flutter gen-l10n
```

### Theme Customization
The app uses a centralized theme system in `lib/core/theme.dart`:
```dart
class AppColors {
  static const Color primary = Color(0xFFFFA700); // Orange
  static const Color secondary = Color(0xFF607D8B); // Blue Grey
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);
}
```

## 🎯 Recent Updates & Improvements

### Production Ready & Google Play Store (Latest)
- ✅ **Android API 35 Compliance**: Updated for Google Play Store requirements
- ✅ **Firebase Configuration**: Updated SHA-1 certificates for authentication
- ✅ **Player Image System Fix**: Enhanced cross-platform image handling
- ✅ **Release Build Optimization**: Signed AAB ready for Play Store submission
- ✅ **Plugin Compatibility**: Compile SDK 36 for latest plugin support

### Translation System Overhaul
- ✅ **Complete Screen Localization**: All major user-facing screens fully translated (Italian/English)
- ✅ **Centralized Translation Keys**: Replaced hardcoded localization logic with ARB key lookups
- ✅ **Dashboard Translations**: Loading states, error messages, and user feedback fully localized
- ✅ **Players Screen Consistency**: Filter labels, empty states, and pluralization properly translated
- ✅ **Enhanced ARB Management**: Comprehensive translation keys for all UI elements
- ✅ **Code Quality**: Consistent `AppLocalizations.of(context)!` pattern throughout codebase

### UI/UX Enhancements
- ✅ **Speed Dial FAB**: Expandable floating action button on home screen
- ✅ **Player Carousel**: Swipeable cards with dot indicators (2 per view)
- ✅ **Bottom Sheets**: Modern draggable forms replacing dialogs
- ✅ **Hero Player Cards**: Large background images with floating stats badges
- ✅ **Mobile Optimization**: Fixed overflow errors and responsive design
- ✅ **Consistent Headers**: Orange icons across all screen headers

### Design System
- ✅ **Dark Theme**: Professional dark UI with orange accents
- ✅ **Material 3**: Updated to latest Material Design components
- ✅ **Card-Based Layout**: Clean, elevated card designs
- ✅ **Typography**: Optimized font sizes and spacing for mobile
- ✅ **Color System**: Centralized AppColors class for consistent theming

### Functionality
- ✅ **Multi-Language**: Language selection with flag indicators
- ✅ **Settings Panel**: Comprehensive preferences and team management
- ✅ **Form Validation**: Improved user feedback and error handling
- ✅ **Navigation**: Persistent bottom tabs with proper routing

## Key Models

### Player
- Personal information (name, birth date, position)
- Photo management with cross-platform support
- Statistics tracking (goals, assists, cards)
- Medical and emergency contact information

### Training
- Session scheduling with date, time, location
- Training objectives and notes
- Attendance tracking with player photos
- Integration with player statistics

### Match
- Match scheduling and opponent information
- Player convocations and team selection
- Individual and team statistics tracking
- Performance metrics and ratings

## Photo Management Details

### Upload Process
1. **Selection**: User selects photo from gallery
2. **Validation**: Format and size checking (max 2MB)
3. **Processing**: Platform-specific handling (data URL vs file path)
4. **Storage**: Permanent storage in app directory
5. **Display**: Immediate update across all screens

### Cross-Platform Handling
```dart
// Web: Convert to data URL
final bytes = await imageFile.readAsBytes();
final dataUrl = 'data:image/jpeg;base64,${base64Encode(bytes)}';

// Mobile: Copy to permanent location
final permanentFile = await sourceFile.copy(permanentPath);
```

### UI Integration
- **Immediate Updates**: Real-time photo display after upload
- **Error Feedback**: User-friendly validation messages
- **Loading States**: Visual feedback during upload process
- **Fallback Display**: Player initials when no photo available

## 🚀 Future Roadmap

### Planned Features
- **Firebase Integration**: Cloud storage and real-time synchronization
- **Offline Support**: Enhanced offline-first architecture with sync
- **Advanced Analytics**: Detailed performance metrics and insights
- **Export Features**: PDF reports, CSV exports, and data visualization
- **Push Notifications**: Match reminders and training alerts
- **Team Communication**: In-app messaging and announcements

### Technical Improvements
- **Performance Optimization**: Image caching and lazy loading
- **Accessibility**: Full screen reader and keyboard navigation support
- **Testing**: Comprehensive unit, widget, and integration test suite
- **CI/CD**: Automated build, testing, and deployment pipeline
- **Web Performance**: Progressive Web App (PWA) capabilities

### Firebase & Cloud Integration ✅
- ✅ **Firebase Authentication**: Google Sign-In with email/password support
- ✅ **Cloud Firestore**: Real-time data synchronization across devices
- ✅ **Firebase Storage**: Cloud image hosting with automatic compression
- ✅ **Firebase Analytics**: User behavior tracking and feature analytics
- ✅ **Hybrid Storage**: Local-first architecture with cloud sync capabilities
- ✅ **SHA-1 Configuration**: Updated certificates for production authentication

### Enhanced Player Management ✅
- ✅ **Image System Overhaul**: Firebase Storage integration with smart compression
- ✅ **Cross-Platform Images**: Robust handling of web URLs, local files, and base64 data
- ✅ **Enhanced Player Screen**: Card-based layout with Italian football terminology
- ✅ **Position Filtering System**: Smart filter buttons with bilingual support
- ✅ **Football Organization**: Logical position grouping (Attacco/Centro Campo/Difesa)
- ✅ **Professional Position Terms**: Authentic Italian football positions (Attaccante, Trequartista, Mediano, etc.)
- ✅ **Speed Dial Integration**: Quick player creation from dashboard with navigation redirects

### Production Ready ✅
- ✅ **Android API 35**: Google Play Store compliance with latest requirements
- ✅ **Release Builds**: Signed AAB files ready for distribution
- ✅ **Plugin Compatibility**: All dependencies support latest Android SDK
- ✅ **Build Optimization**: Tree-shaken fonts and optimized bundle size
- ✅ **Translation System**: Complete Italian/English localization
- ✅ **Modern UI**: Dark theme with consistent orange branding and Material 3

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/new-feature`)
3. Commit changes (`git commit -m 'Add new feature'`)
4. Push to branch (`git push origin feature/new-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For support and questions, please open an issue on the GitHub repository.