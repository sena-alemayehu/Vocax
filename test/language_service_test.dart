import 'package:flutter_test/flutter_test.dart';
import 'package:vocax/services/language_service.dart';
import 'package:vocax/services/voice_service.dart';

void main() {
  test('finds a language by code', () {
    expect(LanguageService.byCode('om').name, 'Afaan Oromoo');
    expect(LanguageService.byCode('fr').speechLocale, 'fr_FR');
    expect(LanguageService.byCode('es').subtitle, 'Spanish');
    expect(LanguageService.byCode('am').shortLabel, 'AM');
  });

  test('offers the seven languages', () {
    expect(
      LanguageService.supported.map((l) => l.code),
      ['en', 'am', 'om', 'ti', 'fr', 'es', 'zh'],
    );
    expect(LanguageService.byCode('zh').name, '中文');
    expect(LanguageService.byCode('ti').name, 'ትግርኛ');
  });

  test('matches recognizer locales by language', () {
    final chinese = LanguageService.byCode('zh');
    expect(chinese.isIn(['en_US', 'zh_TW']), isTrue);
    expect(chinese.isIn(['en_US', 'fr-FR']), isFalse);
    expect(languageOf('am-ET'), 'am');
  });

  test('falls back to English for unknown codes', () {
    expect(LanguageService.byCode('xx').code, 'en');
    expect(LanguageService.byCode(null).code, 'en');
  });

  test('speech timeout gives a friendly message', () {
    expect(
      VoiceService.friendlyError('error_speech_timeout'),
      contains('did not hear anything'),
    );
  });
}
