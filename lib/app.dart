import 'package:flutter/material.dart';

import 'screens/welcome_screen.dart';
import 'services/settings_service.dart';
import 'theme.dart';

class VocaxApp extends StatelessWidget {
  const VocaxApp({super.key, required this.settings});

  final SettingsService settings;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: settings,
      builder: (context, child) {
        return MaterialApp(
          title: 'Vocax',
          debugShowCheckedModeBanner: false,
          theme: buildVocaxTheme(Brightness.light),
          darkTheme: buildVocaxTheme(Brightness.dark),
          themeMode: settings.themeMode,
          home: WelcomeScreen(settings: settings),
        );
      },
    );
  }
}
