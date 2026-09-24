import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

/// Coloured circle with the player's initials.
class PlayerAvatar extends StatelessWidget {
  const PlayerAvatar({
    super.key,
    required this.name,
    required this.seed,
    this.size = 44,
  });

  final String name;

  /// Stable value (e.g. player id) used to pick the colour.
  final String seed;
  final double size;

  static const _palette = [
    AppColors.violet,
    AppColors.electricBlue,
    AppColors.coral,
    Color(0xFF16B08A),
    Color(0xFFF08A24),
    Color(0xFFB04AD8),
  ];

  static String initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((s) => s.isNotEmpty);
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      final chars = parts.first.characters;
      return chars.take(2).toString().toUpperCase();
    }
    return (parts.first.characters.first + parts.elementAt(1).characters.first)
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final color = _palette[seed.hashCode.abs() % _palette.length];
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [color, Color.lerp(color, Colors.black, 0.25)!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Text(
          initials(name),
          textScaler: TextScaler.noScaling,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: size * 0.36,
          ),
        ),
      ),
    );
  }
}
