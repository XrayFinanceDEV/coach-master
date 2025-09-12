import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

const String _localeBoxName = 'locale_settings';
const String _localeKey = 'selected_locale';

// Change StateNotifier to Notifier
class LocaleNotifier extends Notifier<Locale> {

  // The build method replaces the constructor for initial state and setup
  @override
  Locale build() {
    _loadLocale(); // Load the locale asynchronously
    return const Locale('en'); // Initial default state
  }

  Future<void> _loadLocale() async {
    try {
      final box = await Hive.openBox(_localeBoxName);
      final localeCode = box.get(_localeKey, defaultValue: 'en') as String;
      // Use state = newValue to update the state
      state = Locale(localeCode);
    } catch (e) {
      // If there's an error, fallback to English
      state = const Locale('en');
    }
  }

  Future<void> setLocale(Locale locale) async {
    try {
      final box = await Hive.openBox(_localeBoxName);
      await box.put(_localeKey, locale.languageCode);
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