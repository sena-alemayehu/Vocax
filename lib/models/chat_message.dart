import 'dart:typed_data';

import 'installed_app.dart';

enum ChatRole { user, assistant }

/// Progress of opening an app from a voice command.
enum AppLaunchStatus { none, opening, opened, failed }

/// One bubble in the conversation.
class ChatMessage {
  ChatMessage({
    required this.role,
    required this.text,
    this.app,
    this.appIcon,
    this.launchStatus = AppLaunchStatus.none,
  });

  factory ChatMessage.user(String text) {
    return ChatMessage(role: ChatRole.user, text: text);
  }

  factory ChatMessage.assistant(
    String text, {
    InstalledApp? app,
    Uint8List? appIcon,
    AppLaunchStatus launchStatus = AppLaunchStatus.none,
  }) {
    return ChatMessage(
      role: ChatRole.assistant,
      text: text,
      app: app,
      appIcon: appIcon,
      launchStatus: launchStatus,
    );
  }

  final ChatRole role;
  final String text;

  /// Set when the reply is about opening an app.
  final InstalledApp? app;
  final Uint8List? appIcon;

  AppLaunchStatus launchStatus;
}
