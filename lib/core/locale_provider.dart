import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coachmaster/services/firestore_user_settings_repository.dart';
import 'package:coachmaster/core/firestore_repository_providers.dart';

class LocaleNotifier extends Notifier<Locale> {
  @override
  Locale build() {
    _loadLocale(); // Load the locale asynchronously
    return const Locale('it'); // Italian by default for new users
  }

  Future<void> _loadLocale() async {
    try {
      final userSettingsRepo = ref.read(userSettingsRepositoryProvider);
      final localeCode = await userSettingsRepo.getSelectedLocale();
      state = Locale(localeCode);
    } catch (e) {
      // If there's an error, fallback to Italian
      state = const Locale('it');
    }
  }

  Future<void> setLocale(Locale locale) async {
    try {
      final userSettingsRepo = ref.read(userSettingsRepositoryProvider);
      await userSettingsRepo.setSelectedLocale(locale.languageCode);
      state = locale;
    } catch (e) {
      // Handle error silently, keep current locale
    }
  }
}

// Change StateNotifierProvider to NotifierProvider
final localeProvider = NotifierProvider<LocaleNotifier, Locale>(
  () => LocaleNotifier(),
);