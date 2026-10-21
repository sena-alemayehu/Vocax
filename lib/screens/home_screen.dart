import 'package:flutter/material.dart';

import '../services/command_handler.dart';
import '../services/language_service.dart';
import '../services/voice_service.dart';
import '../theme.dart';
import '../widgets/copyright_footer.dart';
import '../widgets/gradient_button.dart';
import '../widgets/language_selector.dart';
import '../widgets/status_orb.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final VoiceService _voice = VoiceService();
  final CommandHandler _commands = CommandHandler();
  final LanguageService _languages = LanguageService();

  bool _listening = false;
  bool _busy = false;
  bool _speaking = false;
  bool _responding = false;

  String _recognizedText = '';
  String _status = 'Tap the button and say "Hello Vocax".';

  @override
  void initState() {
    super.initState();
    _voice
      ..onListeningChanged = (value) {
        if (mounted) setState(() => _listening = value);
      }
      ..onSpeakingChanged = (value) {
        if (mounted) setState(() => _speaking = value);
      }
      ..onError = (message) {
        if (!mounted) return;
        setState(() {
          _listening = false;
          _speaking = false;
          _status = message;
        });
      };
    _voice.configureTts();
  }

  @override
  void dispose() {
    _voice.dispose();
    super.dispose();
  }

  Future<void> _startListening() async {
    if (_busy || _listening || _responding) return;

    setState(() {
      _busy = true;
      _status = 'Checking speech recognition...';
      _recognizedText = '';
    });

    try {
      final language = _languages.current;
      final started = await _voice.startListening(
        localeId: language.speechLocale,
        onResult: _onSpeechResult,
      );

      if (!mounted) return;

      if (!started) {
        setState(() {
          _listening = false;
          _status =
              'Speech recognition is unavailable. Check your microphone permission and Android speech service.';
        });
        return;
      }

      setState(() {
        _listening = true;
        _status = _voice.usedFallbackLocale
            ? 'Listening... ${language.name} is not installed on this device, so the system language is used.'
            : 'Listening in ${language.name}... Say "Hello Vocax".';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _listening = false;
        _status = 'Could not start listening: $error';
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _onSpeechResult(String words, bool isFinal) {
    if (!mounted) return;
    setState(() => _recognizedText = words);

    if (isFinal && words.trim().isNotEmpty) {
      _respond(words.trim());
    }
  }

  Future<void> _respond(String words) async {
    if (_responding) return;
    _responding = true;

    try {
      await _voice.stopListening();
      if (!mounted) return;

      setState(() {
        _listening = false;
        _status = 'Vocax is preparing a response...';
      });

      final reply = await _commands.handle(words);
      await _voice.speak(reply);
      if (!mounted) return;

      setState(() {
        _speaking = false;
        _status = 'Response complete. Tap to try again.';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _speaking = false;
        _listening = false;
        _status = 'Could not respond: $error';
      });
    } finally {
      _responding = false;
    }
  }

  Future<void> _stopListening() async {
    try {
      await _voice.stopListening();
      if (!mounted) return;
      setState(() {
        _listening = false;
        _status = 'Listening stopped.';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _listening = false;
        _status = 'Could not stop listening: $error';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final idle = !_listening && !_busy && !_responding;

    return Scaffold(
      body: Container(
        decoration: vocaxBackground(),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              children: [
                const SizedBox(height: 16),
                const Text(
                  'Vocax',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                LanguageSelector(
                  languages: LanguageService.supported,
                  selected: _languages.current,
                  enabled: idle,
                  onSelected: (language) =>
                      setState(() => _languages.select(language)),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: MediaQuery.of(context).size.height * 0.5,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          StatusOrb(listening: _listening, speaking: _speaking),
                          const SizedBox(height: 32),
                          const Text(
                            'Your voice. Your world.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _status,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 15,
                              height: 1.4,
                            ),
                          ),
                          if (_recognizedText.isNotEmpty) ...[
                            const SizedBox(height: 24),
                            _HeardCard(text: _recognizedText),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
                GradientButton(
                  label: _busy
                      ? 'Please wait...'
                      : _listening
                          ? 'Stop Listening'
                          : 'Start Listening',
                  leadingIcon:
                      _listening ? Icons.stop_rounded : Icons.mic_rounded,
                  onPressed: _busy
                      ? null
                      : _listening
                          ? _stopListening
                          : _startListening,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Listening lasts up to 30 seconds per session.',
                  style: TextStyle(color: Colors.white38, fontSize: 12),
                ),
                const SizedBox(height: 16),
                const CopyrightFooter(),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HeardCard extends StatelessWidget {
  const _HeardCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: kBlue.withValues(alpha: 0.35)),
      ),
      child: Column(
        children: [
          const Text(
            'I heard:',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.white60,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18),
          ),
        ],
      ),
    );
  }
}
