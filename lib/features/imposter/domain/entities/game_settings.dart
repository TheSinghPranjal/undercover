import 'package:flutter/foundation.dart';

import '../enums/app_theme_preference.dart';
import '../enums/difficulty.dart';

@immutable
class GameSettings {
  const GameSettings({
    this.difficulty = Difficulty.easy,
    this.imposterCount = 1,
    this.showHint = false,
    this.theme = AppThemePreference.system,
    this.soundEnabled = false,
    this.hapticsEnabled = true,
    this.animationsEnabled = true,
    this.allowDuplicateNames = false,
    this.tapToReveal = false,
  });

  final Difficulty difficulty;
  final int imposterCount;
  final bool showHint;
  final AppThemePreference theme;
  final bool soundEnabled;
  final bool hapticsEnabled;
  final bool animationsEnabled;
  final bool allowDuplicateNames;

  /// Accessibility fallback: reveal with a single tap instead of press & hold.
  final bool tapToReveal;

  GameSettings copyWith({
    Difficulty? difficulty,
    int? imposterCount,
    bool? showHint,
    AppThemePreference? theme,
    bool? soundEnabled,
    bool? hapticsEnabled,
    bool? animationsEnabled,
    bool? allowDuplicateNames,
    bool? tapToReveal,
  }) => GameSettings(
    difficulty: difficulty ?? this.difficulty,
    imposterCount: imposterCount ?? this.imposterCount,
    showHint: showHint ?? this.showHint,
    theme: theme ?? this.theme,
    soundEnabled: soundEnabled ?? this.soundEnabled,
    hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
    animationsEnabled: animationsEnabled ?? this.animationsEnabled,
    allowDuplicateNames: allowDuplicateNames ?? this.allowDuplicateNames,
    tapToReveal: tapToReveal ?? this.tapToReveal,
  );

  @override
  bool operator ==(Object other) =>
      other is GameSettings &&
      other.difficulty == difficulty &&
      other.imposterCount == imposterCount &&
      other.showHint == showHint &&
      other.theme == theme &&
      other.soundEnabled == soundEnabled &&
      other.hapticsEnabled == hapticsEnabled &&
      other.animationsEnabled == animationsEnabled &&
      other.allowDuplicateNames == allowDuplicateNames &&
      other.tapToReveal == tapToReveal;

  @override
  int get hashCode => Object.hash(
    difficulty,
    imposterCount,
    showHint,
    theme,
    soundEnabled,
    hapticsEnabled,
    animationsEnabled,
    allowDuplicateNames,
    tapToReveal,
  );
}
