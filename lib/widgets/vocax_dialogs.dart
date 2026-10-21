import 'package:flutter/material.dart';

import '../theme.dart';

/// Dialog listing what you can say to Vocax.
Future<void> showCommandsDialog(BuildContext context) {
  Widget command(String phrase, String result) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(phrase, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(result, style: TextStyle(color: context.textSecondary)),
        ],
      ),
    );
  }

  return showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text('Voice commands'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              command('"Hello Vocax"', 'Vocax greets you.'),
              command('"What is your name?"', 'Vocax introduces itself.'),
              command(
                '"Open YouTube"',
                'Also Google, Maps, Gmail, WhatsApp, Telegram, Facebook.',
              ),
              command('"Call <name>"', 'Coming soon.'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Close'),
          ),
        ],
      );
    },
  );
}

/// The standard About dialog with the Vocax icon.
void showAboutVocax(BuildContext context) {
  showAboutDialog(
    context: context,
    applicationName: 'Vocax',
    applicationVersion: '1.0.0',
    applicationIcon: ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.asset('assets/icons/app_icon.png', width: 48, height: 48),
    ),
    applicationLegalese: '© ${DateTime.now().year} Sena Alemayehu',
    children: const [
      SizedBox(height: 12),
      Text('A multilingual AI voice assistant for everyday life.'),
    ],
  );
}
