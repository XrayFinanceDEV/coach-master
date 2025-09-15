# Firebase Setup Instructions

## Current Status
✅ **Demo Firebase configuration is working** - The app will run with demo Firebase config for development and testing.

## For Production: Real Firebase Project Setup

To connect to a real Firebase project instead of the demo configuration:

### 1. Create Firebase Project
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Create a project"
3. Choose project name (e.g., "coachmaster-prod")
4. Enable Google Analytics (optional)

### 2. Enable Required Services
In your Firebase project console:

**Authentication:**
1. Go to Authentication > Sign-in method
2. Enable "Email/Password" provider
3. Configure authorized domains if needed

**Firestore Database:**
1. Go to Firestore Database
2. Click "Create database"
3. Start in "test mode" (can be secured later)
4. Choose location closest to your users

**Storage (if using file uploads):**
1. Go to Storage
2. Click "Get started"
3. Use default security rules for now

### 3. Install Firebase CLI (if not already installed)
```bash
npm install -g firebase-tools
firebase login
```

### 4. Configure Flutter App
```bash
# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Navigate to your project directory
cd /path/to/your/flutter/project

# Configure Firebase for your Flutter project
flutterfire configure
```

This will:
- Create `firebase_options.dart` with real configuration
- Set up platform-specific config files
- Replace the demo configuration

### 5. Update Security Rules

**Firestore Security Rules** (`firestore.rules`):
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can only access their own data
    match /users/{userId}/{document=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

**Storage Security Rules** (`storage.rules`):
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

### 6. Deploy Security Rules
```bash
firebase deploy --only firestore:rules
firebase deploy --only storage
```

## Current Demo Configuration

The app is currently configured with demo Firebase settings in `lib/firebase_options.dart`:

- **Project ID**: `coachmaster-demo`
- **App Domain**: `coachmaster-demo.firebaseapp.com`

This allows the app to run and test Firebase functionality without requiring a real Firebase project during development.

## Environment-Specific Configuration

For different environments (dev, staging, prod), you can:

1. Create separate Firebase projects for each environment
2. Use different `firebase_options.dart` files
3. Configure build flavors to use appropriate configs

## Testing the Configuration

The app includes:
- ✅ Firebase Authentication with email/password
- ✅ Firestore database for sync
- ✅ Offline-first architecture
- ✅ Real-time sync when online
- ✅ User data isolation

Test by:
1. Running the app: `flutter run`
2. Creating a new account in onboarding
3. Adding seasons, teams, players, trainings, matches
4. Data will sync to Firebase when online

## Troubleshooting

**"FirebaseOptions cannot be null" error:**
- ✅ Fixed with proper configuration in `main.dart`

**Authentication errors:**
- Check that Email/Password is enabled in Firebase Console
- Verify domain authorization

**Firestore permission errors:**
- Check security rules allow authenticated users to read/write their data
- Verify user is properly authenticated

**Web-specific issues:**
- Ensure Firebase Hosting is configured if deploying to web
- Check that Firebase project supports web platform