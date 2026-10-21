import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'language_service.dart';

/// App settings (theme and language), saved on the device.
class SettingsService extends ChangeNotifier {
  static const String _darkModeKey = 'dark_mode';
  static const String _languageKey = 'language';

  bool _darkMode = true;
  String _languageCode = LanguageService.supported.first.code;

  bool get darkMode => _darkMode;

  ThemeMode get themeMode => _darkMode ? ThemeMode.dark : ThemeMode.light;

  String get languageCode => _languageCode;

  VocaxLanguage get language => LanguageService.byCode(_languageCode);

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _darkMode = prefs.getBool(_darkModeKey) ?? true;
      _languageCode = LanguageService.byCode(prefs.getString(_languageKey)).code;
    } catch (_) {
      // Fall back to the defaults when storage is unavailable.
    }
  }

  Future<void> setDarkMode(bool value) async {
    if (_darkMode == value) return;
    _darkMode = value;
    notifyListeners();
    await _save((prefs) => prefs.setBool(_darkModeKey, value));
  }

  Future<void> toggleTheme() => setDarkMode(!_darkMode);

  Future<void> setLanguage(String code) async {
    final resolved = LanguageService.byCode(code).code;
    if (_languageCode == resolved) return;
    _languageCode = resolved;
    notifyListeners();
    await _save((prefs) => prefs.setString(_languageKey, resolved));
  }

  Future<void> _save(Future<bool> Function(SharedPreferences prefs) write) async {
    try {
      await write(await SharedPreferences.getInstance());
    } catch (_) {
      // The setting still applies for this session.
    }
  }
}
