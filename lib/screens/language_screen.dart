import 'package:flutter/material.dart';

import '../services/language_service.dart';
import '../services/settings_service.dart';
import '../theme.dart';

/// Full-screen language picker.
class LanguageScreen extends StatelessWidget {
  const LanguageScreen({super.key, required this.settings});

  final SettingsService settings;

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
                  const SizedBox(height: 24),
                  for (final language in LanguageService.supported)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: _LanguageCard(
                        language: language,
                        selected: language.code == settings.languageCode,
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

class _LanguageCard extends StatelessWidget {
  const _LanguageCard({
    required this.language,
    required this.selected,
    required this.onTap,
  });

  final VocaxLanguage language;
  final bool selected;
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
