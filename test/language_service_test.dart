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
