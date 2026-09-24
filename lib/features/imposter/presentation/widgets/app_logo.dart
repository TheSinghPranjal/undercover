import 'package:flutter/material.dart';

import '../../../../app/theme/app_tokens.dart';
import '../../../../app/theme/game_colors.dart';

/// Stack of tilted secret cards with a detective on top.
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 140});

  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = GameColors.of(context);
    Widget card(
      List<Color> gradient,
      double angle,
      Offset offset, {
      Widget? child,
    }) => Transform.translate(
      offset: offset,
      child: Transform.rotate(
        angle: angle,
        child: Container(
          width: size * 0.62,
          height: size * 0.84,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(size * 0.12),
            gradient: LinearGradient(
              colors: gradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.4),
              width: 2,
            ),
            boxShadow: AppShadows.glow(gradient.first),
          ),
          child: child,
        ),
      ),
    );

    return ExcludeSemantics(
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            card(colors.imposterCard, -0.28, Offset(-size * 0.14, size * 0.02)),
            card(colors.civilianCard, 0.24, Offset(size * 0.14, size * 0.02)),
            card(
              colors.cardBack,
              0,
              Offset.zero,
              child: Text('🕵️', style: TextStyle(fontSize: size * 0.32)),
            ),
          ],
        ),
      ),
    );
  }
}
