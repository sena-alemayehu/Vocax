class VocaxLanguage {
  const VocaxLanguage({
    required this.code,
    required this.name,
    required this.speechLocale,
  });

  final String code;
  final String name;

  /// Locale id passed to the speech recognizer.
  final String speechLocale;
}

/// Languages Vocax can listen in, and the one currently selected.
class LanguageService {
  static const List<VocaxLanguage> supported = [
    VocaxLanguage(code: 'en', name: 'English', speechLocale: 'en_US'),
    VocaxLanguage(code: 'om', name: 'Afaan Oromo', speechLocale: 'om_ET'),
    VocaxLanguage(code: 'am', name: 'Amharic', speechLocale: 'am_ET'),
  ];

  VocaxLanguage _current = supported.first;

  VocaxLanguage get current => _current;

  void select(VocaxLanguage language) => _current = language;
}
