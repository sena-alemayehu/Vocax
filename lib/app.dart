import 'package:flutter/material.dart';

import 'screens/welcome_screen.dart';
import 'theme.dart';

class VocaxApp extends StatelessWidget {
  const VocaxApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vocax',
      debugShowCheckedModeBanner: false,
      theme: buildVocaxTheme(),
      home: const WelcomeScreen(),
    );
  }
}
