// lib/core/theme/app_theme.dart
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;

abstract final class AppTheme {
  static const income = Color(0xFF30D158);
  static const expense = Color(0xFFFF453A);

  static final light = _build(Brightness.light);
  static final dark = _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0A84FF), brightness: brightness),
      scaffoldBackgroundColor: isDark ? Colors.black : const Color(0xFFF2F2F7),
      cardColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
      splashFactory: NoSplash.splashFactory,
      pageTransitionsTheme: const PageTransitionsTheme(builders: {
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.android: CupertinoPageTransitionsBuilder(),
      }),
    );
  }
}