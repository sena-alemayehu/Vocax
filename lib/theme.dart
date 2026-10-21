import 'package:flutter/material.dart';

// Design tokens shared by every screen and widget.
const Color kBackground = Color(0xFF050A14);
const Color kSurface = Color(0xFF0F1626);
const Color kLightBackground = Color(0xFFF5F7FF);
const Color kBlue = Color(0xFF3D8BFF);
const Color kViolet = Color(0xFF7B5CFF);

const LinearGradient kBrandGradient = LinearGradient(
  begin: Alignment.centerLeft,
  end: Alignment.centerRight,
  colors: [kBlue, kViolet],
);

ThemeData buildVocaxTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;

  return ThemeData(
    brightness: brightness,
    scaffoldBackgroundColor: dark ? kBackground : kLightBackground,
    colorScheme: ColorScheme.fromSeed(
      seedColor: kBlue,
      brightness: brightness,
    ),
    drawerTheme: DrawerThemeData(
      backgroundColor: dark ? kSurface : Colors.white,
    ),
    useMaterial3: true,
  );
}

/// Colors that change between the light and dark theme.
extension VocaxColors on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  Color get textPrimary => isDark ? Colors.white : const Color(0xFF0B1020);

  Color get textSecondary =>
      isDark ? Colors.white70 : const Color(0xFF4A5470);

  Color get textMuted => isDark ? Colors.white38 : const Color(0xFF8A93A8);

  Color get surfaceColor => isDark ? kSurface : Colors.white;
}

/// Soft radial glow used as the background of every screen.
BoxDecoration vocaxBackground(
  BuildContext context, {
  Alignment center = const Alignment(0, -0.5),
}) {
  final dark = context.isDark;

  return BoxDecoration(
    gradient: RadialGradient(
      center: center,
      radius: 1.0,
      colors: dark
          ? const [Color(0xFF0B1630), kBackground]
          : const [Color(0xFFE3EAFF), kLightBackground],
    ),
  );
}
