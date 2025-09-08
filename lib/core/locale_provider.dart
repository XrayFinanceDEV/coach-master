import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

const String _localeBoxName = 'locale_settings';
const String _localeKey = 'selected_locale';

class LocaleNotifier extends StateNotifier<Locale> {
  LocaleNotifier() : super(const Locale('en')) {
    _loadLocale();
  }

  Future<void> _loadLocale() async {
    try {
      final box = await Hive.openBox(_localeBoxName);
      final localeCode = box.get(_localeKey, defaultValue: 'en') as String;
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

final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  return LocaleNotifier();
});