import 'package:flutter/material.dart';

import '../services/language_service.dart';
import '../theme.dart';

/// Row of chips for choosing the language Vocax listens in.
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
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 4,
      children: [
        for (final language in languages)
          ChoiceChip(
            label: Text(language.name),
            selected: language.code == selected.code,
            showCheckmark: false,
            selectedColor: kBlue.withValues(alpha: 0.35),
            backgroundColor: kSurface,
            onSelected: enabled ? (_) => onSelected(language) : null,
          ),
      ],
    );
  }
}
