import 'package:flutter/material.dart';

import '../services/language_service.dart';
import '../theme.dart';

/// Dropdown pill (globe + "EN") for choosing the language Vocax listens in.
class LanguageSelector extends StatelessWidget {
  const LanguageSelector({
    super.key,
    required this.languages,
    required this.selected,
    required this.onSelected,
    this.enabled = true,
  });

  final List<VocaxLanguage> languages;
  final VocaxLanguage selected;
  final ValueChanged<VocaxLanguage> onSelected;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: PopupMenuButton<VocaxLanguage>(
        enabled: enabled,
        tooltip: 'Language',
        position: PopupMenuPosition.under,
        onSelected: onSelected,
        itemBuilder: (context) => [
          for (final language in languages)
            PopupMenuItem<VocaxLanguage>(
              value: language,
              child: Row(
                children: [
                  Expanded(child: Text(language.name)),
                  if (language.code == selected.code)
                    const Icon(Icons.check_rounded, size: 18, color: kBlue),
                ],
              ),
            ),
        ],
        child: Container(
          padding: const EdgeInsets.fromLTRB(10, 6, 4, 6),
          decoration: BoxDecoration(
            color: context.surfaceColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: kBlue.withValues(alpha: 0.35)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.language_rounded, size: 18, color: context.textPrimary),
              const SizedBox(width: 6),
              Text(
                selected.shortLabel,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: context.textPrimary,
                ),
              ),
              Icon(
                Icons.arrow_drop_down_rounded,
                size: 22,
                color: context.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
