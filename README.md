# CoachMaster ⚽

A modern, comprehensive Flutter sports team management application designed for coaches to efficiently manage players, training sessions, matches, and team statistics. Built with a beautiful dark theme and orange accent colors, featuring intuitive navigation and powerful management tools.

## ✨ Key Features

### 🏠 Dashboard & Home
- **Modern Speed Dial FAB**: Quick access to add players, trainings, and matches
- **Team Statistics Cards**: 2-column mobile-optimized stats display
- **Player Carousel**: Swipeable player cards with dots indicator (2 cards per view)
- **Season/Team Management**: Streamlined team and season selection
- **Responsive Design**: Mobile-first with overflow protection

### 👥 Enhanced Player Management  
- **Card-Based Layout**: Hero-style player cards (2 per row) with professional football imagery
- **Position Filtering**: Smart filter buttons (All/Attack/Midfield/Defense) with Italian terminology
- **Football Organization**: Logical position grouping (Attacco → Centro Campo → Difesa)
- **Bilingual Support**: Dynamic Italian/English labels based on app language settings
- **Professional Position Terms**: Authentic Italian football terminology (Attaccante, Trequartista, etc.)
- **Orange Stats Badges**: Goals and assists displayed as floating overlay badges
- **Advanced Player Profiles**: Complete information with stunning visual design
- **Bottom Sheet Forms**: Modern, draggable forms with organized position dropdowns
- **Cross-Platform Photos**: Web and mobile image support with validation
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
- **Orange Accents**: Consistent orange (#FF7F00) primary color system
- **Material 3**: Modern Material Design 3.0 components and styling
- **Consistent Headers**: Orange icons + screen names across all screens

### User Experience
- **Bottom Sheets**: Modern, draggable forms replacing traditional dialogs
- **Card-Based Design**: Clean card layouts with proper elevation and spacing
- **Mobile Optimized**: Responsive design preventing overflow errors
- **Intuitive Navigation**: Persistent bottom navigation with tab icons

## Photo Upload System

### Supported Formats
- **JPEG/JPG**: Standard photo format
- **PNG**: With transparency support
- **WEBP**: Modern web format

### Features
- **File Size Limit**: Maximum 2MB per photo
- **Format Validation**: Automatic format checking with user feedback
- **Cross-Platform**: Works on web, mobile, and desktop
- **Real-time Preview**: Immediate photo preview in dialogs
- **Persistent Storage**: Photos saved permanently to app directory

### Technical Implementation
- **Web**: Base64 data URLs for browser persistence
- **Mobile/Desktop**: Local file system storage in app documents
- **Image Compression**: Automatic quality optimization (85%)
- **Error Handling**: Graceful fallback with user-friendly messages

## 🏗️ Architecture

### Tech Stack
- **Framework**: Flutter 3.35.2+ with Dart
- **State Management**: Riverpod 2.5.1 for reactive state management
- **Navigation**: GoRouter 14.1.4 with persistent bottom navigation
- **Local Storage**: Hive 2.2.3 with type adapters
- **UI Components**: Material Design 3.0 with custom theming
- **Photo Handling**: Cross-platform image management
- **Build Tools**: build_runner for code generation

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

### Code Generation
Run after modifying model annotations:
```bash
flutter packages pub run build_runner build --delete-conflicting-outputs
flutter packages pub run build_runner watch  # For continuous generation
```

### Theme Customization
The app uses a centralized theme system in `lib/core/theme.dart`:
```dart
class AppColors {
  static const Color primary = Color(0xFFFF7F00); // Orange
  static const Color secondary = Color(0xFF607D8B); // Blue Grey
  // ... other colors
}
```

## 🎯 Recent Updates & Improvements

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

### Completed Recently ✅
- ✅ **Enhanced Player Screen**: Card-based layout with Italian football terminology
- ✅ **Position Filtering System**: Smart filter buttons with bilingual support  
- ✅ **Football Organization**: Logical position grouping (Attacco/Centro Campo/Difesa)
- ✅ **Bilingual Interface**: Dynamic Italian/English translation for all player components
- ✅ **Professional Position Terms**: Authentic Italian football positions (Attaccante, Trequartista, Mediano, etc.)
- ✅ **Speed Dial Integration**: Quick player creation from dashboard with navigation redirects
- ✅ Multi-language support foundation with language picker
- ✅ Modern UI components (bottom sheets, carousels, speed dials)
- ✅ Dark theme with consistent orange branding
- ✅ Mobile-responsive design with overflow protection
- ✅ Enhanced player management with hero-style cards
- ✅ Centralized theme system and design components

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