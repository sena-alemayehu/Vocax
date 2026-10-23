import 'dart:typed_data';

import 'installed_app.dart';

/// What a voice command produced.
class CommandResult {
  const CommandResult({
    required this.reply,
    this.app,
    this.appIcon,
    this.launch,
    this.webUrl,
    this.webTitle,
  });

  /// Text Vocax says and shows.
  final String reply;

  /// The app being opened, if the command was "open <app>".
  final InstalledApp? app;
  final Uint8List? appIcon;

  /// Opens the app. Run it after the result card is on screen.
  final Future<bool> Function()? launch;

  /// A web page to show inside Vocax AI (search results, a website).
  final String? webUrl;
  final String? webTitle;
}
