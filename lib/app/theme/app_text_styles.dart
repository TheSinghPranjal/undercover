import 'package:flutter/material.dart';

/// Chunky, expressive type scale for a party game.
abstract final class AppTextStyles {
  static TextTheme textTheme(Color onBackground) {
    TextStyle s(
      double size,
      FontWeight weight, {
      double spacing = 0,
      double? height,
    }) => TextStyle(
      fontSize: size,
      fontWeight: weight,
      letterSpacing: spacing,
      height: height,
      color: onBackground,
    );
    return TextTheme(
      displayLarge: s(56, FontWeight.w900, spacing: -1, height: 1.0),
      displayMedium: s(44, FontWeight.w900, spacing: -0.5, height: 1.05),
      displaySmall: s(34, FontWeight.w900, height: 1.1),
      headlineLarge: s(30, FontWeight.w800, height: 1.15),
      headlineMedium: s(26, FontWeight.w800, height: 1.2),
      headlineSmall: s(22, FontWeight.w800),
      titleLarge: s(20, FontWeight.w700),
      titleMedium: s(17, FontWeight.w700),
      titleSmall: s(15, FontWeight.w700),
      bodyLarge: s(17, FontWeight.w500, height: 1.4),
      bodyMedium: s(15, FontWeight.w500, height: 1.4),
      bodySmall: s(13, FontWeight.w500, height: 1.35),
      labelLarge: s(16, FontWeight.w800, spacing: 1.2),
      labelMedium: s(13, FontWeight.w700, spacing: 1.4),
      labelSmall: s(11, FontWeight.w800, spacing: 1.6),
    );
  }
}
