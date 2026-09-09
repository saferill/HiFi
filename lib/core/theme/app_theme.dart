import 'package:flutter/material.dart';

class AppTheme {
  static const Color defaultSeedColor = Colors.deepPurple;

  static ThemeData light({ColorScheme? dynamicColorScheme}) {
    final scheme = dynamicColorScheme ??
        ColorScheme.fromSeed(
          seedColor: defaultSeedColor,
          brightness: Brightness.light,
        );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      brightness: Brightness.light,
    );
  }

  static ThemeData dark({ColorScheme? dynamicColorScheme}) {
    final scheme = dynamicColorScheme ??
        ColorScheme.fromSeed(
          seedColor: defaultSeedColor,
          brightness: Brightness.dark,
        );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      brightness: Brightness.dark,
    );
  }
}
