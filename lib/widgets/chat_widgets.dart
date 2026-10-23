import 'package:flutter/material.dart';

import '../models/chat_message.dart';
import '../theme.dart';

/// One bubble in the conversation: yours on the right, Vocax on the left.
class ChatBubble extends StatelessWidget {
  const ChatBubble({super.key, required this.message, this.faded = false});

  final ChatMessage message;

  /// Draws the bubble dimmed (used for words still being recognised).
  final bool faded;

  @override
  Widget build(BuildContext context) {
    final bubble = message.role == ChatRole.user
        ? _UserBubble(text: message.text)
        : _AssistantBubble(message: message);

    return Opacity(opacity: faded ? 0.6 : 1, child: bubble);
  }
}

class _UserBubble extends StatelessWidget {
  const _UserBubble({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(left: 56, bottom: 14),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
        decoration: BoxDecoration(
          gradient: kBrandGradient,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: kBlue.withValues(alpha: 0.25),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _AssistantBubble extends StatelessWidget {
  const _AssistantBubble({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14, right: 40),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Avatar(),
          const SizedBox(width: 12),
          Flexible(
            child: Container(
              width: message.app != null ? double.infinity : null,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: context.surfaceColor,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: context.isDark
                      ? Colors.white10
                      : const Color(0xFFE3E8F5),
                ),
                boxShadow: context.isDark
                    ? const []
                    : [
                        BoxShadow(
                          color: const Color(0xFF3D4F8F).withValues(alpha: 0.08),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
              ),
              child: message.app == null
                  ? Text(
                      message.text,
                      style: TextStyle(
                        fontSize: 16,
                        height: 1.4,
                        color: context.textPrimary,
                      ),
                    )
                  : _AppResult(message: message),
            ),
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar();

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: Image.asset(
        'assets/icons/app_icon.png',
        width: 44,
        height: 44,
        fit: BoxFit.cover,
      ),
    );
  }
}

/// "Opening YouTube." + the app icon + its name + progress.
class _AppResult extends StatelessWidget {
  const _AppResult({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final app = message.app!;
    final icon = message.appIcon;

    final Widget status;
    switch (message.launchStatus) {
      case AppLaunchStatus.opened:
        status = const _Status(
          icon: Icons.check_circle_rounded,
          color: Color(0xFF2EAD5B),
          text: 'App opened successfully.',
        );
        break;
      case AppLaunchStatus.failed:
        status = const _Status(
          icon: Icons.error_rounded,
          color: Color(0xFFD93025),
          text: 'Could not open the app.',
        );
        break;
      default:
        status = const _Status(
          icon: Icons.hourglass_top_rounded,
          color: kBlue,
          text: 'Opening...',
        );
    }

    return Column(
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            message.text,
            style: TextStyle(fontSize: 17, color: context.textPrimary),
          ),
        ),
        const SizedBox(height: 18),
        Container(
          width: 84,
          height: 84,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: context.isDark ? Colors.white10 : Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: context.isDark ? Colors.white12 : const Color(0xFFE3E8F5),
            ),
          ),
          child: icon != null
              ? Image.memory(icon, fit: BoxFit.contain, gaplessPlayback: true)
              : Icon(Icons.apps_rounded, size: 40, color: context.textSecondary),
        ),
        const SizedBox(height: 12),
        Text(
          app.name,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: context.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        status,
      ],
    );
  }
}

class _Status extends StatelessWidget {
  const _Status({required this.icon, required this.color, required this.text});

  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            text,
            style: TextStyle(fontSize: 14, color: context.textSecondary),
          ),
        ),
      ],
    );
  }
}
