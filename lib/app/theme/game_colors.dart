import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Game-specific colours that don't map onto [ColorScheme] roles.
@immutable
class GameColors extends ThemeExtension<GameColors> {
  const GameColors({
    required this.background,
    required this.cardBack,
    required this.civilianCard,
    required this.imposterCard,
    required this.onCard,
    required this.hint,
    required this.highlight,
    required this.particle,
  });

  /// Page background gradient, top to bottom.
  final List<Color> background;

  /// Face-down card gradient.
  final List<Color> cardBack;
  final List<Color> civilianCard;
  final List<Color> imposterCard;
  final Color onCard;
  final Color hint;
  final Color highlight;
  final Color particle;

  static const light = GameColors(
    background: [AppColors.offWhite, Color(0xFFF1EBFF)],
    cardBack: [AppColors.violet, AppColors.indigoDeep],
    civilianCard: [AppColors.electricBlue, AppColors.violet],
    imposterCard: [AppColors.coral, AppColors.coralDeep],
    onCard: Colors.white,
    hint: AppColors.warmYellow,
    highlight: AppColors.warmYellow,
    particle: AppColors.violet,
  );

  static const dark = GameColors(
    background: [AppColors.navy, AppColors.indigoDeep],
    cardBack: [Color(0xFF8E63FF), Color(0xFF3A2A8C)],
    civilianCard: [AppColors.electricBlue, AppColors.violet],
    imposterCard: [AppColors.coral, AppColors.coralDeep],
    onCard: Colors.white,
    hint: AppColors.warmYellow,
    highlight: AppColors.warmYellow,
    particle: AppColors.violetSoft,
  );

  static GameColors of(BuildContext context) =>
      Theme.of(context).extension<GameColors>()!;

  @override
  GameColors copyWith({
    List<Color>? background,
    List<Color>? cardBack,
    List<Color>? civilianCard,
    List<Color>? imposterCard,
    Color? onCard,
    Color? hint,
    Color? highlight,
    Color? particle,
  }) => GameColors(
    background: background ?? this.background,
    cardBack: cardBack ?? this.cardBack,
    civilianCard: civilianCard ?? this.civilianCard,
    imposterCard: imposterCard ?? this.imposterCard,
    onCard: onCard ?? this.onCard,
    hint: hint ?? this.hint,
    highlight: highlight ?? this.highlight,
    particle: particle ?? this.particle,
  );

  @override
  GameColors lerp(GameColors? other, double t) {
    if (other == null) return this;
    List<Color> l(List<Color> a, List<Color> b) => [
      for (var i = 0; i < a.length; i++) Color.lerp(a[i], b[i], t)!,
    ];
    return GameColors(
      background: l(background, other.background),
      cardBack: l(cardBack, other.cardBack),
      civilianCard: l(civilianCard, other.civilianCard),
      imposterCard: l(imposterCard, other.imposterCard),
      onCard: Color.lerp(onCard, other.onCard, t)!,
      hint: Color.lerp(hint, other.hint, t)!,
      highlight: Color.lerp(highlight, other.highlight, t)!,
      particle: Color.lerp(particle, other.particle, t)!,
    );
  }
}
