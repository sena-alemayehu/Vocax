import 'package:flutter/material.dart';

import '../services/settings_service.dart';
import '../theme.dart';
import 'copyright_footer.dart';

/// Side menu: language, theme, voice commands and About.
class VocaxDrawer extends StatelessWidget {
  const VocaxDrawer({
    super.key,
    required this.settings,
    required this.onLanguageTap,
    required this.onCommandsTap,
    required this.onAboutTap,
  });

  final SettingsService settings;
  final VoidCallback onLanguageTap;
  final VoidCallback onCommandsTap;
  final VoidCallback onAboutTap;

  /// Closes the drawer first, then runs [action] on the screen behind it.
  void _closeThen(BuildContext context, VoidCallback action) {
    Navigator.of(context).pop();
    action();
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: ListenableBuilder(
          listenable: settings,
          builder: (context, child) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.asset(
                          'assets/icons/app_icon.png',
                          width: 56,
                          height: 56,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Vocax',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: context.textPrimary,
                              ),
                            ),
                            Text(
                              'Your voice. Your world.',
                              style: TextStyle(
                                fontSize: 13,
                                color: context.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.language_rounded),
                  title: const Text('Language'),
                  subtitle: Text(settings.language.name),
                  onTap: () => _closeThen(context, onLanguageTap),
                ),
                SwitchListTile(
                  secondary: Icon(
                    settings.darkMode
                        ? Icons.dark_mode_rounded
                        : Icons.light_mode_rounded,
                  ),
                  title: const Text('Dark mode'),
                  value: settings.darkMode,
                  onChanged: (value) => settings.setDarkMode(value),
                ),
                ListTile(
                  leading: const Icon(Icons.record_voice_over_rounded),
                  title: const Text('Voice commands'),
                  onTap: () => _closeThen(context, onCommandsTap),
                ),
                ListTile(
                  leading: const Icon(Icons.info_outline_rounded),
                  title: const Text('About'),
                  onTap: () => _closeThen(context, onAboutTap),
                ),
                const Spacer(),
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: CopyrightFooter(),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
