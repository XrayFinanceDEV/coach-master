import 'package:hive/hive.dart';
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
    await _box?.put(_settingsKey, settings);
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

