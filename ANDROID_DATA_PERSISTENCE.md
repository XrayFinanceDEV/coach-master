# Android Data Persistence Issue & Solutions

## The Problem
Android emulator data gets cleared between development sessions while web data persists in browser.

## Why This Happens
1. **Development Mode**: `flutter run` often reinstalls the APK, clearing app data
2. **Emulator Snapshots**: Emulator may reset to clean state
3. **Debug Builds**: Different storage behavior than release builds

## Solutions Applied

### 1. ✅ Fixed Hive Initialization
Changed from manual directory setup to `Hive.initFlutter()` for proper app-specific storage:

```dart
// Before (problematic)
final directory = await getApplicationDocumentsDirectory();
Hive.init('${directory.path}/coachmaster_db');

// After (better)
await Hive.initFlutter('coachmaster_db');
```

### 2. Development Workarounds

#### Option A: Use Hot Reload Instead of Full Restart
- Use `r` for hot reload instead of stopping and restarting
- Data persists during hot reloads

#### Option B: Emulator Snapshot
```bash
# Save emulator state with data
adb shell am broadcast -a android.intent.action.BOOT_COMPLETED

# Use emulator snapshots to preserve state
```

#### Option C: Use Physical Device
- Physical Android devices have better data persistence
- Less likely to clear app data between development sessions

### 3. Test Data Persistence

To verify if persistence is working:

1. Add some data in the app
2. Stop the app (don't force kill emulator)
3. Restart with `flutter run`
4. Check if data remains

### 4. Release Build Persistence
Data persistence works properly in release builds:

```bash
flutter build apk --release
flutter install --release
```

## Current Status
✅ Hive initialization improved to use proper app storage
✅ Better debug logging added
✅ Removed problematic document directory usage

The improved initialization should provide better data persistence in the Android emulator during development.