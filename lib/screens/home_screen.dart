import 'package:flutter/material.dart';

import '../services/command_handler.dart';
import '../services/language_service.dart';
import '../services/settings_service.dart';
import '../services/voice_service.dart';
import '../theme.dart';
import '../widgets/copyright_footer.dart';
import '../widgets/gradient_button.dart';
import '../widgets/language_selector.dart';
import '../widgets/status_orb.dart';
import '../widgets/vocax_dialogs.dart';
import '../widgets/vocax_drawer.dart';
import 'language_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.settings});

  final SettingsService settings;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final VoiceService _voice = VoiceService();
  final CommandHandler _commands = CommandHandler();

  bool _listening = false;
  bool _busy = false;
  bool _speaking = false;
  bool _responding = false;

  String _recognizedText = '';
  String _status = 'Tap the button and say "Hello Vocax".';

  VocaxLanguage get _language => widget.settings.language;

  @override
  void initState() {
    super.initState();
    widget.settings.addListener(_onSettingsChanged);
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
    widget.settings.removeListener(_onSettingsChanged);
    _voice.dispose();
    super.dispose();
  }

  void _onSettingsChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _startListening() async {
    if (_busy || _listening || _responding) return;

    setState(() {
      _busy = true;
      _status = 'Checking speech recognition...';
      _recognizedText = '';
    });

    try {
      final language = _language;
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
            ? 'Listening... ${language.englishName} is not installed on this phone, so the system language is used.'
            : 'Listening in ${language.englishName}... Say "Hello Vocax".';
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
      key: _scaffoldKey,
      drawer: VocaxDrawer(
        settings: widget.settings,
        onLanguageTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (context) => LanguageScreen(settings: widget.settings),
          ),
        ),
        onCommandsTap: () => showCommandsDialog(context),
        onAboutTap: () => showAboutVocax(context),
      ),
      body: Container(
        decoration: vocaxBackground(context),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                _Header(
                  language: _language,
                  languageEnabled: idle,
                  darkMode: widget.settings.darkMode,
                  onMenu: () => _scaffoldKey.currentState?.openDrawer(),
                  onLanguage: (language) =>
                      widget.settings.setLanguage(language.code),
                  onToggleTheme: widget.settings.toggleTheme,
                ),
                Expanded(
                  child: SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: MediaQuery.of(context).size.height * 0.55,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            StatusOrb(
                              listening: _listening,
                              speaking: _speaking,
                            ),
                            const SizedBox(height: 32),
                            Text(
                              'Your voice. Your world.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w600,
                                color: context.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _status,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: context.textSecondary,
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
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: GradientButton(
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
                ),
                const SizedBox(height: 12),
                Text(
                  'Listening lasts up to 30 seconds per session.',
                  style: TextStyle(color: context.textMuted, fontSize: 12),
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

/// Top bar: menu, title, language dropdown and theme toggle.
class _Header extends StatelessWidget {
  const _Header({
    required this.language,
    required this.languageEnabled,
    required this.darkMode,
    required this.onMenu,
    required this.onLanguage,
    required this.onToggleTheme,
  });

  final VocaxLanguage language;
  final bool languageEnabled;
  final bool darkMode;
  final VoidCallback onMenu;
  final ValueChanged<VocaxLanguage> onLanguage;
  final VoidCallback onToggleTheme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          IconButton(
            onPressed: onMenu,
            tooltip: 'Menu',
            color: context.textPrimary,
            icon: const Icon(Icons.menu_rounded, size: 28),
          ),
          Expanded(
            child: Text(
              'Vocax',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: context.textPrimary,
              ),
            ),
          ),
          LanguageSelector(
            languages: LanguageService.supported,
            selected: language,
            enabled: languageEnabled,
            onSelected: onLanguage,
          ),
          IconButton(
            onPressed: onToggleTheme,
            tooltip: darkMode ? 'Switch to light mode' : 'Switch to dark mode',
            color: context.textPrimary,
            icon: Icon(
              darkMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
            ),
          ),
        ],
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
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: kBlue.withValues(alpha: 0.35)),
      ),
      child: Column(
        children: [
          Text(
            'I heard:',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: context.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, color: context.textPrimary),
          ),
        ],
      ),
    );
  }
}
