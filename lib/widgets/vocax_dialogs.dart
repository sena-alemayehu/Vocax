import 'package:flutter/material.dart';

import '../theme.dart';

/// Dialog listing what you can say to Vocax.
Future<void> showCommandsDialog(BuildContext context) {
  Widget section(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 15,
          color: kBlue,
        ),
      ),
    );
  }

  Widget command(String phrase, String result) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
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
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                section('Apps'),
                command('"Open YouTube" / "Open WhatsApp"', 'Opens any app on your phone.'),
                section('Calls and messages'),
                command('"Call Mom" / "Call 0911223344"', 'Calls a contact or number.'),
                command(
                  '"Send a message to Mom saying I am late"',
                  'Opens the message ready to send.',
                ),
                section('Search and maps'),
                command('"Search for weather in Addis Ababa"', 'Searches Google.'),
                command('"Play Ethiopian music on YouTube"', 'Searches YouTube.'),
                command('"Navigate to Bole Airport"', 'Opens directions in Maps.'),
                section('Phone controls'),
                command('"Turn on the flashlight"', 'Also "turn off the flashlight".'),
                command('"Volume up" / "Volume 50" / "Mute"', 'Changes the volume.'),
                command('"Pause" / "Next song" / "Play"', 'Controls the music app.'),
                command('"Set an alarm for 7 30 AM"', 'Sets an alarm.'),
                command('"Set a timer for 5 minutes"', 'Starts a timer.'),
                command('"Take a photo"', 'Opens the camera.'),
                command('"Open Wi-Fi settings"', 'Also Bluetooth, location, display.'),
                command('"What is my battery level?"', 'Tells you the battery percent.'),
                command('"What time is it?"', 'Tells the time and date.'),
              ],
            ),
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
