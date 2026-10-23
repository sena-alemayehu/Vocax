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

  /// True when one of the recognizer's [localeIds] is this language.
  bool isIn(Iterable<String> localeIds) {
    return localeIds.any((id) => languageOf(id) == code);
  }
}

/// `en_US`, `en-US` and `EN` all give `en`.
String languageOf(String localeId) {
  return localeId.toLowerCase().replaceAll('-', '_').split('_').first;
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
      code: 'ti',
      name: 'ትግርኛ',
      englishName: 'Tigrinya',
      subtitle: 'Tigrinya',
      badge: 'TI',
      color: Color(0xFF7B5CFF),
      speechLocale: 'ti_ET',
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
    VocaxLanguage(
      code: 'zh',
      name: '中文',
      englishName: 'Chinese',
      subtitle: 'Chinese (Mandarin)',
      badge: 'ZH',
      color: Color(0xFFF29900),
      speechLocale: 'zh_CN',
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
