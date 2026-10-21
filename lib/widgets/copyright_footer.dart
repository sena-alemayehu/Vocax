import 'package:flutter/material.dart';

/// Copyright footer shown at the bottom of each screen.
class CopyrightFooter extends StatelessWidget {
  const CopyrightFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      '© ${DateTime.now().year} Sena Alemayehu. All rights reserved.',
      textAlign: TextAlign.center,
      style: const TextStyle(
        color: Colors.white38,
        fontSize: 12,
        letterSpacing: 0.2,
      ),
    );
  }
}
