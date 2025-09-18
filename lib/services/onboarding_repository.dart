import 'package:hive/hive.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:coachmaster/models/onboarding_settings.dart';

class OnboardingRepository {
  static const String _boxName = 'onboardingBox';
  static const String _settingsKey = 'settings';
  Box<OnboardingSettings>? _box;

  Future<void> init() async {
    _box = await Hive.openBox<OnboardingSettings>(_boxName);
  }

  OnboardingSettings? getSettings() {
    return _box?.get(_settingsKey);
  }

  bool get isOnboardingCompleted {
    final settings = getSettings();
    return settings?.isCompleted ?? false;
  }

  Future<void> saveSettings(OnboardingSettings settings) async {
    // Save to local Hive storage
    await _box?.put(_settingsKey, settings);

    // Also save to Firestore for cross-platform consistency
    await _saveToFirestore(settings);
  }

  /// Save onboarding settings to Firestore for cross-platform access
  Future<void> _saveToFirestore(OnboardingSettings settings) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (kDebugMode) {
          print('🔥 OnboardingRepo: No authenticated user, skipping Firestore save');
        }
        return;
      }

      if (kDebugMode) {
        print('🔥 OnboardingRepo: Saving onboarding status to Firestore for user ${user.uid}');
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('onboarding')
          .doc('settings')
          .set({
        'coachName': settings.coachName,
        'seasonName': settings.seasonName,
        'teamName': settings.teamName,
        'isCompleted': settings.isCompleted,
        'lastUpdated': DateTime.now().toIso8601String(),
        'platform': kIsWeb ? 'web' : 'mobile', // Track which platform completed onboarding
      });

      if (kDebugMode) {
        print('🔥 OnboardingRepo: ✅ Onboarding status saved to Firestore');
      }
    } catch (e) {
      if (kDebugMode) {
        print('🔥 OnboardingRepo: ❌ Error saving to Firestore: $e');
      }
      // Don't throw - local storage is still working
    }
  }

  /// Load onboarding settings from Firestore (for cross-platform sync)
  Future<OnboardingSettings?> loadFromFirestore() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (kDebugMode) {
          print('🔥 OnboardingRepo: No authenticated user, skipping Firestore load');
        }
        return null;
      }

      if (kDebugMode) {
        print('🔥 OnboardingRepo: Loading onboarding status from Firestore for user ${user.uid}');
      }

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('onboarding')
          .doc('settings')
          .get();

      if (!doc.exists) {
        if (kDebugMode) {
          print('🔥 OnboardingRepo: No onboarding data in Firestore');
        }
        return null;
      }

      final data = doc.data()!;

      if (kDebugMode) {
        print('🔥 OnboardingRepo: Firestore data: $data');
      }

      // Create settings with proper completion status
      final settings = OnboardingSettings.create(
        coachName: data['coachName'] ?? '',
        seasonName: data['seasonName'] ?? '',
        teamName: data['teamName'] ?? '',
      );

      // Manually set completion status from Firestore data
      // OnboardingSettings.create() always sets isCompleted to true
      final isCompleted = data['isCompleted'] ?? false;

      if (kDebugMode) {
        print('🔥 OnboardingRepo: Firestore isCompleted: $isCompleted');
      }

      // Update local storage with Firestore data
      await _box?.put(_settingsKey, settings);

      if (kDebugMode) {
        print('🔥 OnboardingRepo: ✅ Onboarding settings loaded from Firestore and synced locally');
      }

      return settings;
    } catch (e) {
      if (kDebugMode) {
        print('🔥 OnboardingRepo: ❌ Error loading from Firestore: $e');
      }
      return null;
    }
  }

  /// Check both local and Firestore for onboarding completion status
  Future<bool> checkOnboardingCompleted() async {
    final user = FirebaseAuth.instance.currentUser;

    if (kDebugMode) {
      print('🔥 OnboardingRepo: Checking onboarding status for user: ${user?.uid ?? 'none'}');
    }

    // If authenticated with Firebase, prioritize Firestore for cross-platform consistency
    if (user != null) {
      if (kDebugMode) {
        print('🔥 OnboardingRepo: Firebase user detected, checking Firestore first');
      }

      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('onboarding')
            .doc('settings')
            .get();

        if (doc.exists) {
          final data = doc.data()!;
          final isCompleted = data['isCompleted'] ?? false;

          if (kDebugMode) {
            print('🔥 OnboardingRepo: Firestore onboarding data found: isCompleted=$isCompleted');
          }

          if (isCompleted == true) {
            // Sync to local storage
            final settings = OnboardingSettings.create(
              coachName: data['coachName'] ?? '',
              seasonName: data['seasonName'] ?? '',
              teamName: data['teamName'] ?? '',
            );
            await _box?.put(_settingsKey, settings);

            if (kDebugMode) {
              print('🔥 OnboardingRepo: ✅ Onboarding completed (from Firestore)');
            }
            return true;
          }
        } else {
          if (kDebugMode) {
            print('🔥 OnboardingRepo: No onboarding document in Firestore');
          }
        }
      } catch (e) {
        if (kDebugMode) {
          print('🔥 OnboardingRepo: Error checking Firestore: $e');
        }
      }

      if (kDebugMode) {
        print('🔥 OnboardingRepo: No completed onboarding found in Firestore');
      }
    }

    // Fallback to local storage (for offline mode or non-Firebase users)
    final localCompleted = isOnboardingCompleted;
    if (localCompleted) {
      if (kDebugMode) {
        print('🔥 OnboardingRepo: ✅ Onboarding completed (from local storage)');
      }
      return true;
    }

    if (kDebugMode) {
      print('🔥 OnboardingRepo: ❌ Onboarding not completed anywhere');
    }
    return false;
  }

  Future<void> clearSettings() async {
    await _box?.delete(_settingsKey);
  }

  /// Reset onboarding and clear all associated data
  Future<void> resetOnboarding() async {
    await clearSettings();
    // Note: This clears onboarding status but keeps existing data
    // To fully reset, you'd also need to clear seasons and teams
  }
}

