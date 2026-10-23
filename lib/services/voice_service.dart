import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import 'language_service.dart';

/// Wraps speech recognition (speech_to_text) and speech output (flutter_tts).
class VoiceService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _tts = FlutterTts();

  bool _speechReady = false;

  /// True when the requested locale was not installed and the system default
  /// was used instead.
  bool usedFallbackLocale = false;

  void Function(bool listening)? onListeningChanged;
  void Function(bool speaking)? onSpeakingChanged;
  void Function(String message)? onError;

  bool get isListening => _speech.isListening;

  /// Turns recognizer error codes into something a person can act on.
  static String friendlyError(String code) {
    switch (code) {
      case 'error_speech_timeout':
      case 'error_no_match':
        return 'I did not hear anything. Tap the mic and speak after it starts listening.';
      case 'error_permission':
        return 'Microphone permission is needed. Open the menu, App Permissions, and allow the microphone.';
      case 'error_network':
      case 'error_network_timeout':
      case 'error_server':
        return 'Voice recognition could not connect. Check your internet, or download the offline voice pack for your language (menu, Language, Install voice).';
      case 'error_language_not_supported':
      case 'error_language_unavailable':
        return 'This language is not available in the speech service on this phone. See menu, Language, Install voice.';
      case 'error_audio':
        return 'There was a problem with the microphone. Try again.';
      case 'error_busy':
        return 'The speech service is busy. Wait a moment and try again.';
      default:
        return 'Speech error: $code';
    }
  }

  Future<void> configureTts() async {
    _tts.setStartHandler(() => onSpeakingChanged?.call(true));
    _tts.setCompletionHandler(() => onSpeakingChanged?.call(false));
    _tts.setCancelHandler(() => onSpeakingChanged?.call(false));
    _tts.setErrorHandler((message) {
      onSpeakingChanged?.call(false);
      onError?.call('Speech output error: $message');
    });

    try {
      await _tts.setLanguage('en-US');
      await _tts.setSpeechRate(0.45);
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);
      await _tts.awaitSpeakCompletion(true);
    } catch (error) {
      onError?.call('Voice setup failed: $error');
    }
  }

  Future<bool> _ensureSpeechReady() async {
    if (_speechReady) return true;

    _speechReady = await _speech.initialize(
      onStatus: (_) => onListeningChanged?.call(_speech.isListening),
      onError: (error) {
        onListeningChanged?.call(false);
        onError?.call(friendlyError(error.errorMsg));
      },
    );
    return _speechReady;
  }

  /// Locale ids the phone's speech service knows (empty if unavailable).
  Future<List<String>> supportedLocales() async {
    if (!await _ensureSpeechReady()) return const [];
    final locales = await _speech.locales();
    return [for (final locale in locales) locale.localeId];
  }

  /// Finds the recognizer locale matching [wanted] (e.g. `om_ET`): the exact
  /// one first, then any locale of the same language (e.g. `zh_TW` for `zh_CN`).
  Future<String?> _resolveLocale(String wanted) async {
    String clean(String value) => value.toLowerCase().replaceAll('-', '_');

    final locales = await _speech.locales();
    for (final locale in locales) {
      if (clean(locale.localeId) == clean(wanted)) return locale.localeId;
    }
    for (final locale in locales) {
      if (languageOf(locale.localeId) == languageOf(wanted)) {
        return locale.localeId;
      }
    }
    return null;
  }

  /// Starts listening. Returns false when speech recognition is unavailable.
  /// With [onDevice] the phone's offline recognizer is used (no internet).
  Future<bool> startListening({
    required String localeId,
    required void Function(String words, bool isFinal) onResult,
    bool onDevice = false,
  }) async {
    if (!await _ensureSpeechReady()) return false;

    await _tts.stop();

    final resolved = await _resolveLocale(localeId);
    usedFallbackLocale = resolved == null;

    await _speech.listen(
      localeId: resolved,
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
      listenOptions: stt.SpeechListenOptions(
        partialResults: true,
        onDevice: onDevice,
      ),
      onResult: (result) => onResult(result.recognizedWords, result.finalResult),
    );
    return true;
  }

  Future<void> stopListening() => _speech.stop();

  /// Speaks [text] and waits until it is finished (at most 12 seconds).
  Future<void> speak(String text) async {
    await _tts.speak(text).timeout(
          const Duration(seconds: 12),
          onTimeout: () => null,
        );
  }

  Future<void> stopSpeaking() => _tts.stop();

  Future<void> dispose() async {
    await _speech.stop();
    await _tts.stop();
  }
}
