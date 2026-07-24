import 'package:flutter/material.dart';

/// Central design system. The emergency palette is deliberately high-contrast
/// and readable under stress / one-handed use.
class AppTheme {
  static const Color emergencyRed = Color(0xFFE53935);
  static const Color emergencyRedDark = Color(0xFFB71C1C);
  static const Color safeGreen = Color(0xFF2E7D32);
  static const Color ink = Color(0xFF1A1A2E);

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: emergencyRed,
      primary: emergencyRed,
      brightness: Brightness.light,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: const Color(0xFFF7F7FA),
      textTheme: const TextTheme(
        headlineMedium: TextStyle(fontWeight: FontWeight.w700, color: ink),
        titleMedium: TextStyle(fontWeight: FontWeight.w600),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(56),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }

  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(
      seedColor: emergencyRed,
      primary: emergencyRed,
      brightness: Brightness.dark,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      brightness: Brightness.dark,
    );
  }
}
