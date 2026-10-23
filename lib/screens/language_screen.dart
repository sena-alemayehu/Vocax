import 'package:flutter/material.dart';

import '../services/device_service.dart';
import '../services/language_service.dart';
import '../services/settings_service.dart';
import '../services/voice_service.dart';
import '../theme.dart';

/// Full-screen language picker, with the voice-pack status of each language.
class LanguageScreen extends StatefulWidget {
  const LanguageScreen({
    super.key,
    required this.settings,
    required this.voice,
    required this.device,
  });

  final SettingsService settings;
  final VoiceService voice;
  final DeviceService device;

  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen>
    with WidgetsBindingObserver {
  SettingsService get settings => widget.settings;

  /// Locale ids the phone's speech service knows. Null while loading.
  List<String>? _locales;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadLocales();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Back from the voice settings: check again.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _loadLocales();
  }

  Future<void> _loadLocales() async {
    List<String> locales;
    try {
      locales = await widget.voice.supportedLocales();
    } catch (_) {
      locales = const [];
    }
    if (mounted) setState(() => _locales = locales);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: vocaxBackground(context, center: const Alignment(0, -0.8)),
        child: SafeArea(
          child: ListenableBuilder(
            listenable: settings,
            builder: (context, child) {
              return ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      tooltip: 'Back',
                      color: context.textPrimary,
                      icon: const Icon(Icons.arrow_back_ios_new_rounded),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      'Select Language',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        color: context.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      'Choose your preferred language',
                      style: TextStyle(
                        fontSize: 17,
                        color: context.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      'Languages marked "Install voice" need a free voice pack '
                      'from your phone\'s speech service. Tap Install voice for '
                      'the steps.',
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.4,
                        color: context.textMuted,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  for (final language in LanguageService.supported)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: _LanguageCard(
                        language: language,
                        selected: language.code == settings.languageCode,
                        voiceStatus: _locales == null
                            ? _VoiceStatus.checking
                            : language.isIn(_locales!)
                                ? _VoiceStatus.ready
                                : _VoiceStatus.missing,
                        onInstall: () => showVoicePackDialog(
                          context,
                          language: language,
                          device: widget.device,
                        ),
                        onTap: () {
                          settings.setLanguage(language.code);
                          Navigator.of(context).pop();
                        },
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

enum _VoiceStatus { checking, ready, missing }

class _LanguageCard extends StatelessWidget {
  const _LanguageCard({
    required this.language,
    required this.selected,
    required this.voiceStatus,
    required this.onInstall,
    required this.onTap,
  });

  final VocaxLanguage language;
  final bool selected;
  final _VoiceStatus voiceStatus;
  final VoidCallback onInstall;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final selectedFill = kBlue.withValues(alpha: context.isDark ? 0.18 : 0.10);

    return Material(
      color: selected ? selectedFill : context.surfaceColor,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: selected ? kBlue : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              _Badge(language: language),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      language.name,
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w600,
                        color: context.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      language.subtitle,
                      style: TextStyle(
                        fontSize: 15,
                        color: context.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    _statusRow(context, voiceStatus, onInstall),
                  ],
                ),
              ),
              if (selected)
                const Icon(Icons.check_circle_rounded, color: kBlue, size: 28)
              else
                Icon(
                  Icons.chevron_right_rounded,
                  color: context.textSecondary,
                  size: 28,
                ),
              const SizedBox(width: 4),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _statusRow(
  BuildContext context,
  _VoiceStatus voiceStatus,
  VoidCallback onInstall,
) {
    switch (voiceStatus) {
      case _VoiceStatus.checking:
        return Text(
          'Checking voice...',
          style: TextStyle(fontSize: 12.5, color: context.textMuted),
        );
      case _VoiceStatus.ready:
        return const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_rounded, size: 15, color: Color(0xFF2EAD5B)),
            SizedBox(width: 5),
            Text(
              'Voice ready',
              style: TextStyle(fontSize: 12.5, color: Color(0xFF2EAD5B)),
            ),
          ],
        );
      case _VoiceStatus.missing:
        return InkWell(
          onTap: onInstall,
          borderRadius: BorderRadius.circular(8),
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.download_rounded, size: 15, color: kBlue),
                SizedBox(width: 5),
                Text(
                  'Install voice',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: kBlue,
                  ),
                ),
              ],
            ),
          ),
        );
    }
}

/// Explains how to add a speech-recognition voice pack for [language].
Future<void> showVoicePackDialog(
  BuildContext context, {
  required VocaxLanguage language,
  required DeviceService device,
}) {
  final hardToFind = language.code == 'om' || language.code == 'ti';

  return showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: Text('Install ${language.englishName} voice'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Android installs voice packs, not apps, so this takes a few taps:',
              ),
              const SizedBox(height: 12),
              Text(
                '1. Tap Open settings.\n'
                '2. Open Speech recognition (or the Google speech service), '
                'then Languages or Offline speech recognition.\n'
                '3. Download ${language.englishName}.\n'
                '4. Come back to Vocax AI. This screen updates by itself.',
                style: const TextStyle(height: 1.5),
              ),
              if (hardToFind) ...[
                const SizedBox(height: 12),
                Text(
                  'Note: ${language.englishName} is not offered by every phone\'s '
                  'speech service. If it is not in the list, your phone cannot '
                  'recognise it yet, and Vocax AI will listen in the closest '
                  'language it has.',
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: dialogContext.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Close'),
          ),
          FilledButton(
            onPressed: () {
              device.openVoiceSettings();
              Navigator.of(dialogContext).pop();
            },
            child: const Text('Open settings'),
          ),
        ],
      );
    },
  );
}

/// Rounded colored square with the two-letter language code.
class _Badge extends StatelessWidget {
  const _Badge({required this.language});

  final VocaxLanguage language;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: language.color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(18),
      ),
      alignment: Alignment.center,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: language.color,
          borderRadius: BorderRadius.circular(11),
        ),
        alignment: Alignment.center,
        child: Text(
          language.badge,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
