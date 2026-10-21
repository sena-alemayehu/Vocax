import 'package:flutter/material.dart';

import '../theme.dart';

/// Glowing circle that shows whether Vocax is idle, listening or speaking.
class StatusOrb extends StatelessWidget {
  const StatusOrb({super.key, required this.listening, required this.speaking});

  final bool listening;
  final bool speaking;

  @override
  Widget build(BuildContext context) {
    final active = listening || speaking;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: 150,
      height: 150,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            kBlue.withValues(alpha: active ? 0.35 : 0.15),
            kViolet.withValues(alpha: active ? 0.35 : 0.15),
          ],
        ),
        border: Border.all(color: kBlue.withValues(alpha: 0.6), width: 2),
        boxShadow: active
            ? [
                BoxShadow(
                  color: kViolet.withValues(alpha: 0.45),
                  blurRadius: 36,
                  spreadRadius: 4,
                ),
              ]
            : const [],
      ),
      child: Icon(
        listening
            ? Icons.graphic_eq_rounded
            : speaking
                ? Icons.volume_up_rounded
                : Icons.mic_none_rounded,
        size: 72,
        color: context.textPrimary,
      ),
    );
  }
}
