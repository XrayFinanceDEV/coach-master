import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _localeKey = 'selected_locale';

class LocaleNotifier extends Notifier<Locale> {
  @override
  Locale build() {
    _loadLocale(); // Load the locale asynchronously
    return const Locale('it'); // Italian by default for new users
  }

  Future<void> _loadLocale() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final localeCode = prefs.getString(_localeKey) ?? 'it';
      state = Locale(localeCode);
    } catch (e) {
      // If there's an error, fallback to Italian
      state = const Locale('it');
    }
  }

  Future<void> setLocale(Locale locale) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_localeKey, locale.languageCode);
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