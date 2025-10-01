# Firebase Integration Plan

This document outlines the comprehensive plan for integrating Firebase Authentication and Firestore database while maintaining offline-first architecture.

## 🎯 Integration Goals

- **Maintain Offline-First**: Excellent offline functionality with Firebase persistence
- **Add Cloud Sync**: Enable automatic data synchronization across devices
- **Simple Authentication**: Email/password + Google Sign-In with Firebase Auth
- **User Isolation**: Each user sees only their own data
- **Minimal Disruption**: Preserve existing UI patterns and state management

## 🏗️ Architecture Overview

### Firestore Database Structure

User-isolated data structure in Firestore:

```
/users/{userId}/
  ├── profile/
  │   └── userDocument {
  │       name: string,
  │       email: string,
  │       createdAt: timestamp,
  │       lastLoginAt: timestamp
  │     }
  │
  ├── seasons/{seasonId} { name, startDate, endDate, ... }
  ├── teams/{teamId} { name, seasonId, description, ... }
  ├── players/{playerId} { firstName, lastName, position, stats, ... }
  ├── trainings/{trainingId} { teamId, date, location, objectives, ... }
  ├── matches/{matchId} { teamId, opponent, date, goalsFor, goalsAgainst, ... }
  ├── notes/{noteId} { linkedId, linkedType, content, ... }
  ├── training_attendance/{attendanceId} { trainingId, playerId, attended, ... }
  ├── match_statistics/{statisticId} { matchId, playerId, goals, assists, rating, ... }
  └── match_convocations/{convocationId} { matchId, playerId, convocated, ... }
```

### Firebase Services

**1. Firebase Authentication**
- Email/password authentication
- Google Sign-In integration
- Password reset functionality
- User profile management

**2. Cloud Firestore**
- Offline persistence enabled by default
- Real-time data synchronization
- User-isolated collections
- Automatic conflict resolution

**3. Firebase Storage**
- Player profile images
- Auto-cleanup (keeps latest 3 images per player)
- Path: `users/{userId}/players/{playerId}/profile_{timestamp}.jpg`

**4. Firebase Analytics** (Optional)
- User behavior tracking
- Feature usage analytics
- Performance monitoring

## 🔥 Implementation Patterns

### Repository Pattern

All repositories follow Firebase-first, offline-capable pattern:

```dart
class FirestorePlayerRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String userId;

  CollectionReference<Map<String, dynamic>> get _collection =>
    _firestore.collection('users').doc(userId).collection('players');

  // Real-time stream
  Stream<Player?> playerStream(String playerId) {
    return _collection.doc(playerId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return Player.fromJson({...doc.data()!, 'id': doc.id});
    });
  }

  // Future-based get (uses offline cache)
  Future<Player?> getPlayer(String playerId) async {
    final doc = await _collection.doc(playerId).get();
    if (!doc.exists) return null;
    return Player.fromJson({...doc.data()!, 'id': doc.id});
  }

  // Write operations
  Future<void> addPlayer(Player player) async {
    await _collection.doc(player.id).set(player.toJson());
  }

  Future<void> updatePlayer(Player player) async {
    await _collection.doc(player.id).update(player.toJson());
  }

  Future<void> deletePlayer(String playerId) async {
    await _collection.doc(playerId).delete();
  }
}
```

### Stream Providers (Riverpod)

All UI components use stream providers for reactive updates:

```dart
// Single item stream
final playerStreamProvider = StreamProvider.family<Player?, String>((ref, playerId) {
  final userId = ref.watch(currentUserProvider)?.uid;
  if (userId == null) return Stream.value(null);

  final repo = ref.watch(playerRepositoryProvider);
  return repo.playerStream(playerId);
});

// List stream
final playersForTeamStreamProvider = StreamProvider.family<List<Player>, String>((ref, teamId) {
  final userId = ref.watch(currentUserProvider)?.uid;
  if (userId == null) return Stream.value([]);

  final repo = ref.watch(playerRepositoryProvider);
  return repo.playersForTeamStream(teamId);
});
```

### UI Pattern

All screens use `.when()` pattern for loading/error/data states:

```dart
@override
Widget build(BuildContext context, WidgetRef ref) {
  final playerAsync = ref.watch(playerStreamProvider(playerId));

  return playerAsync.when(
    data: (player) {
      if (player == null) {
        return Scaffold(
          appBar: AppBar(title: const Text('Not Found')),
          body: const Center(child: Text('Player not found')),
        );
      }

      return Scaffold(
        appBar: AppBar(title: Text('${player.firstName} ${player.lastName}')),
        body: _buildPlayerDetail(player),
      );
    },
    loading: () => const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    ),
    error: (error, stack) => Scaffold(
      appBar: AppBar(title: const Text('Error')),
      body: Center(child: Text('Error: $error')),
    ),
  );
}
```

## 🔒 Security Rules

### Firestore Security Rules

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can only access their own data
    match /users/{userId}/{document=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }

    // Deny all other access
    match /{document=**} {
      allow read, write: if false;
    }
  }
}
```

### Storage Security Rules

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    // Users can only access their own files
    match /users/{userId}/{allPaths=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

## 📦 Dependencies

```yaml
dependencies:
  firebase_core: ^3.10.0
  firebase_auth: ^6.0.2
  cloud_firestore: ^6.0.1
  firebase_storage: ^13.0.1
  firebase_analytics: ^12.0.1
  google_sign_in: ^6.2.1
  flutter_riverpod: ^2.5.1
```

## 🚀 Key Benefits

### For Users
- ✅ **Seamless Offline Experience**: App works perfectly without internet
- ✅ **Cross-Device Sync**: Access data from any device automatically
- ✅ **Secure Authentication**: Firebase-powered login security
- ✅ **Data Backup**: Cloud backup prevents data loss
- ✅ **Real-time Updates**: Live sync when online

### For Development
- ✅ **Scalable Architecture**: Firebase handles user growth
- ✅ **Automatic Offline Caching**: Firebase handles persistence
- ✅ **Better User Management**: User isolation and security built-in
- ✅ **Analytics Ready**: Firebase Analytics integration ready
- ✅ **No Manual Sync Logic**: Firebase handles everything

## 🔧 Development Setup

### 1. Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Create a new project
3. Add Android/iOS/Web apps as needed
4. Download configuration files

### 2. Configure Flutter App

```bash
# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Configure Firebase for Flutter
flutterfire configure

# This generates firebase_options.dart automatically
```

### 3. Enable Firebase Services

**Authentication:**
- Go to Authentication > Sign-in method
- Enable "Email/Password"
- Enable "Google" provider

**Firestore:**
- Go to Firestore Database
- Create database in production mode
- Apply security rules from above

**Storage:**
- Go to Storage
- Get started with default settings
- Apply security rules from above

### 4. Initialize in App

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Enable offline persistence
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  runApp(const ProviderScope(child: MyApp()));
}
```

## 🧪 Testing Strategy

### Unit Tests
- Repository operations with mocked Firestore
- Model serialization/deserialization
- Auth state management

### Integration Tests
- Offline/online transitions
- Cross-device sync scenarios
- Authentication flows

### User Acceptance Tests
- Complete offline workflows
- Real-time sync verification
- Error recovery scenarios

## 📊 Monitoring

### Firebase Console
- Authentication metrics
- Firestore usage and performance
- Storage usage
- Error tracking

### Analytics Events
- User sign-ups and logins
- Feature usage (players, trainings, matches created)
- Error occurrences
- Performance metrics

## 🎯 Migration from Hive

### Key Changes
1. **Synchronous → Asynchronous**: Repository calls now return `Future<T>` or `Stream<T>`
2. **Manual sync → Automatic**: Firebase handles all synchronization
3. **Local only → Cloud + Local**: Data automatically backed up to cloud
4. **No refresh logic**: Streams automatically update UI

### Migration Pattern
```dart
// BEFORE (Hive)
final player = playerRepository.getPlayer(playerId); // Synchronous
Text(player.name)

// AFTER (Firebase)
final playerAsync = ref.watch(playerStreamProvider(playerId));
playerAsync.when(
  data: (player) => Text(player.name),
  loading: () => CircularProgressIndicator(),
  error: (e, _) => Text('Error: $e'),
)
```

---

**This plan provides the foundation for a robust, offline-first, cloud-synced architecture using Firebase services.**
