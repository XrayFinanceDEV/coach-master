# CoachMaster ⚽

Modern Flutter app for sports team management. Dark theme with orange accents, Firebase backend, Italian/English support.

## ✨ Features

**Team Management**
- Player profiles with photos, positions, and statistics
- Training sessions with attendance tracking
- Match scheduling with player convocations
- Real-time performance statistics
- Season and team organization

**Firebase Integration**
- Google Sign-In authentication
- Cloud Firestore for real-time sync across devices
- Firebase Storage for image hosting (~500KB compression)
- Offline-first with automatic synchronization

**UI/UX**
- Material 3 dark theme with orange (#FFA700) accents
- Italian football positions (Attaccante, Trequartista, Mediano, etc.)
- Bottom sheet forms and card-based layouts
- Player carousel with swipeable cards
- Position-based filtering (Attacco/Centrocampo/Difesa)

**Localization**
- Full Italian/English support
- Italian default for new users
- Dynamic UI translations

## 🏗️ Tech Stack

- **Flutter** 3.35.2+ / Dart
- **State Management** Riverpod 2.5.1
- **Navigation** GoRouter 14.1.4
- **Backend** Firebase (Auth, Firestore, Storage, Analytics)
- **UI** Material Design 3.0
- **Platform** Android (API 26-35), iOS, Web

## 🚀 Quick Start

```bash
# Install dependencies
flutter pub get

# Generate localization
flutter gen-l10n

# Run app
flutter run
```

## 📁 Project Structure

```
lib/
├── core/                    # App initialization, routing, theme, providers
├── features/                # Feature modules (dashboard, players, matches, etc.)
├── models/                  # Data models
├── services/                # Firestore repositories
└── l10n/                    # Italian/English translations
```

## 🔧 Development

```bash
flutter analyze              # Static analysis
flutter gen-l10n            # Regenerate translations after ARB changes
flutter build apk           # Android release build
```

## 🎯 Key Models

- **Player** - Profile, position, stats, photos
- **Training** - Sessions, attendance, objectives
- **Match** - Scheduling, convocations, statistics
- **Season/Team** - Organization structure

## 🌐 Firebase Configuration

- **Authentication** - Google Sign-In + email/password
- **Firestore** - User-specific data at `/users/{userId}`
- **Storage** - Images at `/users/{userId}/players/{playerId}/profile_{timestamp}.jpg`
- **Security Rules** - User can only access their own data

## 📱 Production

- **Android** API 35 (Google Play ready)
- **Signed builds** AAB format
- **Localization** Complete IT/EN support
- **Theme** Professional dark mode with orange branding

## 🔐 Firestore Security

```javascript
match /users/{userId} {
  allow read, write: if request.auth != null && request.auth.uid == userId;
  match /{collection}/{document=**} {
    allow read, write: if request.auth != null && request.auth.uid == userId;
  }
}
```

## 📄 License

MIT License - see LICENSE file

---

**Status:** Production Ready | **Version:** 1.0.0+ | **Platform:** Android, iOS, Web
