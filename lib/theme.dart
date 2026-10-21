import 'package:flutter/material.dart';

// Design tokens shared by every screen and widget.
const Color kBackground = Color(0xFF050A14);
const Color kSurface = Color(0xFF0F1626);
const Color kBlue = Color(0xFF3D8BFF);
const Color kViolet = Color(0xFF7B5CFF);

const LinearGradient kBrandGradient = LinearGradient(
  begin: Alignment.centerLeft,
  end: Alignment.centerRight,
  colors: [kBlue, kViolet],
);

ThemeData buildVocaxTheme() {
  return ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: kBackground,
    colorScheme: ColorScheme.fromSeed(
      seedColor: kBlue,
      brightness: Brightness.dark,
    ),
    useMaterial3: true,
  );
}

/// Dark radial glow used as the background of every screen.
BoxDecoration vocaxBackground({Alignment center = const Alignment(0, -0.5)}) {
  return BoxDecoration(
    gradient: RadialGradient(
      center: center,
      radius: 1.0,
      colors: const [Color(0xFF0B1630), kBackground],
    ),
  );
}
