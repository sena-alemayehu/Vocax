import 'package:flutter/material.dart';

class VocaxLanguage {
  const VocaxLanguage({
    required this.code,
    required this.name,
    required this.englishName,
    required this.subtitle,
    required this.badge,
    required this.color,
    required this.speechLocale,
  });

  /// Short id saved in settings, e.g. `om`.
  final String code;

  /// Name written in the language itself, e.g. `Français`.
  final String name;

  /// Name in English, e.g. `French`.
  final String englishName;

  /// Small text under the name on the language screen.
  final String subtitle;

  /// Two-letter badge, e.g. `FR`.
  final String badge;

  /// Badge color.
  final Color color;

  /// Locale id passed to the speech recognizer.
  final String speechLocale;

  /// Short label such as "EN".
  String get shortLabel => badge;
}

/// The languages Vocax can listen in.
class LanguageService {
  static const List<VocaxLanguage> supported = [
    VocaxLanguage(
      code: 'en',
      name: 'English',
      englishName: 'English',
      subtitle: 'General English',
      badge: 'EN',
      color: Color(0xFF2F6BFF),
      speechLocale: 'en_US',
    ),
    VocaxLanguage(
      code: 'am',
      name: 'አማርኛ',
      englishName: 'Amharic',
      subtitle: 'Amharic',
      badge: 'AM',
      color: Color(0xFF1E9E4A),
      speechLocale: 'am_ET',
    ),
    VocaxLanguage(
      code: 'om',
      name: 'Afaan Oromoo',
      englishName: 'Afaan Oromoo',
      subtitle: 'Oromo',
      badge: 'OR',
      color: Color(0xFFD93025),
      speechLocale: 'om_ET',
    ),
    VocaxLanguage(
      code: 'fr',
      name: 'Français',
      englishName: 'French',
      subtitle: 'French',
      badge: 'FR',
      color: Color(0xFF2F6BFF),
      speechLocale: 'fr_FR',
    ),
    VocaxLanguage(
      code: 'es',
      name: 'Español',
      englishName: 'Spanish',
      subtitle: 'Spanish',
      badge: 'ES',
      color: Color(0xFFD93025),
      speechLocale: 'es_ES',
    ),
  ];

  /// Finds a language by its code, falling back to English.
  static VocaxLanguage byCode(String? code) {
    for (final language in supported) {
      if (language.code == code) return language;
    }
    return supported.first;
  }
}
