import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';
import 'app_text_styles.dart';
import 'app_tokens.dart';
import 'game_colors.dart';

abstract final class AppTheme {
  static ThemeData get light => _build(
    ColorScheme.fromSeed(
      seedColor: AppColors.violet,
      brightness: Brightness.light,
    ).copyWith(
      primary: AppColors.violet,
      onPrimary: Colors.white,
      secondary: AppColors.electricBlue,
      tertiary: AppColors.coral,
      surface: AppColors.paper,
      onSurface: AppColors.ink,
      surfaceContainerHighest: const Color(0xFFEDE6FF),
    ),
    GameColors.light,
    buttonColor: AppColors.violet,
  );

  static ThemeData get dark => _build(
    ColorScheme.fromSeed(
      seedColor: AppColors.violet,
      brightness: Brightness.dark,
    ).copyWith(
      primary: const Color(0xFF9B78FF),
      onPrimary: Colors.white,
      secondary: AppColors.electricBlue,
      tertiary: AppColors.coral,
      surface: AppColors.navySurface,
      onSurface: Colors.white,
      surfaceContainerHighest: AppColors.navySurfaceHigh,
    ),
    GameColors.dark,
    // Deeper than the dark primary so white labels keep their contrast.
    buttonColor: AppColors.violet,
  );

  static ThemeData _build(
    ColorScheme scheme,
    GameColors game, {
    required Color buttonColor,
  }) {
    final text = AppTextStyles.textTheme(scheme.onSurface);
    return ThemeData(
      useMaterial3: true,
      fontFamily: AppTextStyles.fontFamily,
      colorScheme: scheme,
      scaffoldBackgroundColor: game.background.first,
      textTheme: text,
      extensions: [game],
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        foregroundColor: scheme.onSurface,
        titleTextStyle: text.titleLarge,
        systemOverlayStyle: scheme.brightness == Brightness.dark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: buttonColor,
          foregroundColor: Colors.white,
        ),
      ),
      cardTheme: CardThemeData(
        color: scheme.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.card),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        border: OutlineInputBorder(
          borderRadius: AppRadius.button,
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.button,
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.button,
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          textStyle: WidgetStatePropertyAll(text.titleSmall),
          shape: const WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: AppRadius.button),
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surface,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.card),
        titleTextStyle: text.headlineSmall,
        contentTextStyle: text.bodyLarge,
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
