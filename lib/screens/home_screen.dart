import 'dart:async';

import 'package:flutter/material.dart';

import '../models/chat_message.dart';
import '../services/command_handler.dart';
import '../services/device_service.dart';
import '../services/language_service.dart';
import '../services/settings_service.dart';
import '../services/voice_service.dart';
import '../theme.dart';
import '../widgets/chat_widgets.dart';
import '../widgets/copyright_footer.dart';
import '../widgets/language_selector.dart';
import '../widgets/mic_button.dart';
import '../widgets/vocax_dialogs.dart';
import '../widgets/vocax_drawer.dart';
import '../widgets/wave_logo.dart';
import 'language_screen.dart';
import 'permissions_screen.dart';
import 'web_screen.dart';

/// What Vocax AI says the first time you tap Start listening.
const String kGreeting =
    "Hello! I'm Vocax Ai Assistance. How can I help you today?";

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.settings});

  final SettingsService settings;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final ScrollController _scroll = ScrollController();
  final DeviceService _device = PlatformDeviceService();
  final VoiceService _voice = VoiceService();
  late final CommandHandler _commands = CommandHandler(device: _device);

  final List<ChatMessage> _messages = [];

  bool _listening = false;
  bool _busy = false;
  bool _speaking = false;
  bool _responding = false;
  bool _online = true;
  bool _greeted = false;

  String _partial = '';
  String _status = 'Tap the mic and say "Hello Vocax".';

  VocaxLanguage get _language => widget.settings.language;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
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
          _partial = '';
          _status = message;
        });
      };
    _voice.configureTts();
    _checkOnline();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.settings.removeListener(_onSettingsChanged);
    _scroll.dispose();
    _voice.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _checkOnline();
  }

  void _onSettingsChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _checkOnline() async {
    final online = await _device.isOnline();
    if (mounted && online != _online) setState(() => _online = online);
  }

  void _add(ChatMessage message) {
    setState(() => _messages.add(message));
    _scrollToEnd();
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _startListening() async {
    if (_busy || _listening || _responding) return;

    setState(() {
      _busy = true;
      _status = 'Getting ready...';
      _partial = '';
    });

    try {
      // First tap after the app opens: say hello.
      if (!_greeted) {
        _greeted = true;
        _add(ChatMessage.assistant(kGreeting));
        widget.settings.markGreeted();
        await _voice.speak(kGreeting);
        if (!mounted) return;
      }

      final online = await _device.isOnline();
      if (!mounted) return;
      _online = online;

      final language = _language;
      final started = await _voice.startListening(
        localeId: language.speechLocale,
        // No internet: use the voice pack stored on the phone.
        onDevice: !online,
        onResult: _onSpeechResult,
      );

      if (!mounted) return;

      if (!started) {
        setState(() {
          _listening = false;
          _status =
              'Speech recognition is unavailable. Open the menu, App Permissions, and allow the microphone.';
        });
        return;
      }

      setState(() {
        _listening = true;
        if (_voice.usedFallbackLocale) {
          _status =
              'Listening... ${language.englishName} voice is not installed on this phone, so the system language is used. See menu, Language.';
        } else if (!online) {
          _status = 'Offline. Listening in ${language.englishName} on this phone...';
        } else {
          _status = 'Listening in ${language.englishName}...';
        }
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
    setState(() => _partial = words);
    _scrollToEnd();

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
        _partial = '';
        _status = 'Thinking...';
      });
      _add(ChatMessage.user(words));

      final result = await _commands.handleFull(words);
      if (!mounted) return;

      final app = result.app;
      if (app != null) {
        // Show the app card first, then open the app.
        final message = ChatMessage.assistant(
          result.reply,
          app: app,
          appIcon: result.appIcon,
          launchStatus: AppLaunchStatus.opening,
        );
        _add(message);
        unawaited(_voice.speak(result.reply));

        await Future<void>.delayed(const Duration(milliseconds: 900));
        final opened = await result.launch?.call() ?? false;
        if (!mounted) return;

        setState(() {
          message.launchStatus =
              opened ? AppLaunchStatus.opened : AppLaunchStatus.failed;
          _status = 'Tap the mic to ask something else.';
        });
        return;
      }

      _add(ChatMessage.assistant(result.reply));

      final webUrl = result.webUrl;
      if (webUrl != null) {
        // Web results open inside Vocax AI.
        unawaited(_voice.speak(result.reply));
        setState(() => _status = 'Tap the mic to ask something else.');
        unawaited(
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (context) => WebScreen(
                title: result.webTitle ?? 'Vocax AI',
                url: webUrl,
              ),
            ),
          ),
        );
        return;
      }

      await _voice.speak(result.reply);
      if (!mounted) return;
      setState(() {
        _speaking = false;
        _status = 'Tap the mic to ask something else.';
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
        _partial = '';
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

  void _open(Widget screen) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    final idle = !_listening && !_busy && !_responding;

    return Scaffold(
      key: _scaffoldKey,
      drawer: VocaxDrawer(
        settings: widget.settings,
        onLanguageTap: () => _open(
          LanguageScreen(
            settings: widget.settings,
            voice: _voice,
            device: _device,
          ),
        ),
        onPermissionsTap: () => _open(PermissionsScreen(device: _device)),
        onCommandsTap: () => showCommandsDialog(context),
        onAboutTap: () => showAboutVocax(context),
      ),
      body: Container(
        decoration: vocaxBackground(context),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _Header(
                  language: _language,
                  languageEnabled: idle,
                  darkMode: widget.settings.darkMode,
                  onMenu: () => _scaffoldKey.currentState?.openDrawer(),
                  onLanguage: (language) =>
                      widget.settings.setLanguage(language.code),
                  onToggleTheme: widget.settings.toggleTheme,
                ),
              ),
              if (!_online) const _OfflineBanner(),
              Expanded(child: _buildConversation(context)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Text(
                  _status,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: context.textSecondary,
                    fontSize: 14,
                    height: 1.35,
                  ),
                ),
              ),
              MicButton(
                listening: _listening,
                speaking: _speaking,
                busy: _busy,
                onPressed: _listening ? _stopListening : _startListening,
              ),
              const CopyrightFooter(),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConversation(BuildContext context) {
    if (_messages.isEmpty && _partial.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const AnimatedWaveLogo(width: 150),
              const SizedBox(height: 24),
              Text(
                'Your Voice. Your World.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: context.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Try: "Open YouTube", "Call Mom", or "Turn on the flashlight".',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.4,
                  color: context.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      controller: _scroll,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      children: [
        for (final message in _messages) ChatBubble(message: message),
        if (_partial.isNotEmpty)
          ChatBubble(message: ChatMessage.user(_partial), faded: true),
      ],
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
              'Vocax AI',
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

class _OfflineBanner extends StatelessWidget {
  const _OfflineBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(20, 4, 20, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF29900).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.wifi_off_rounded, size: 18, color: Color(0xFFF29900)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Offline: apps, calls, alarms and phone controls still work. '
              'Web search needs internet.',
              style: TextStyle(fontSize: 12.5, color: context.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}
