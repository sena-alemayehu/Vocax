import 'package:flutter/material.dart';

import '../services/settings_service.dart';
import '../theme.dart';
import '../widgets/copyright_footer.dart';
import '../widgets/gradient_button.dart';
import '../widgets/wave_logo.dart';
import 'home_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key, required this.settings});

  final SettingsService settings;

  void _getStarted(BuildContext context) {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 450),
        pageBuilder: (context, animation, secondaryAnimation) =>
            HomeScreen(settings: settings),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: vocaxBackground(context, center: const Alignment(0, -0.45)),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              children: [
                const Spacer(flex: 3),
                const AnimatedWaveLogo(),
                const SizedBox(height: 28),
                Text(
                  'Vocax AI',
                  style: TextStyle(
                    fontSize: 56,
                    fontWeight: FontWeight.w600,
                    color: context.textPrimary,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 22),
                Text(
                  'Your Voice. Your World.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w600,
                    color: context.textPrimary,
                  ),
                ),
                const SizedBox(height: 22),
                Text(
                  'A multilingual AI voice assistant\nfor everyday life.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.5,
                    color: context.textSecondary,
                  ),
                ),
                const Spacer(flex: 4),
                GradientButton(
                  label: 'Get Started',
                  icon: Icons.arrow_forward_rounded,
                  onPressed: () => _getStarted(context),
                ),
                const SizedBox(height: 24),
                const CopyrightFooter(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
