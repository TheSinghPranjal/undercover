import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_tokens.dart';
import '../providers/providers.dart';

/// Fixed palette for the illustrated lavender screens (home, player setup).
/// The artwork is light, so these screens stay light regardless of theme.
abstract final class PlayfulColors {
  static const page = Color(0xFFF4EFFD);
  static const ink = Color(0xFF2B2656);
  static const muted = Color(0xFF5E5A78);
  static const soft = Color(0xFF8A84A6);
  static const accent = Color(0xFF6B46E5);
  static const accentDeep = Color(0xFF4B2BB8);
  static const lip = Color(0xFF3A1F9E);
  static const softLip = Color(0xFF8B6AEE);
  static const field = Color(0xFFDCD2F5);
  static const decor = Color(0xFFCDBBF6);
  static const yellow = Color(0xFFFFC53D);
  static const primaryGradient = [Color(0xFF7447EE), Color(0xFF9063FA)];
}

/// Chunky 3D pill in the logo's style: purple outline, glossy top and a solid
/// "lip" underneath that the button sinks into when pressed.
class PillButton extends ConsumerStatefulWidget {
  const PillButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.primary = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool primary;

  @override
  ConsumerState<PillButton> createState() => _PillButtonState();
}

class _PillButtonState extends ConsumerState<PillButton> {
  bool _pressed = false;

  void _setPressed(bool v) {
    if (_pressed != v) setState(() => _pressed = v);
  }

  void _handleTap() {
    ref.read(soundProvider).tap();
    ref.read(hapticsProvider).selection();
    widget.onPressed?.call();
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    if (!enabled) return _disabled();

    final primary = widget.primary;
    final height = primary ? 62.0 : 54.0;
    final lipDepth = primary ? 6.0 : 5.0;
    final depth = _pressed ? 1.0 : lipDepth;
    final lipColor = primary ? PlayfulColors.lip : PlayfulColors.softLip;
    final foreground = primary ? Colors.white : PlayfulColors.accentDeep;

    final face = AnimatedContainer(
      duration: AppDurations.fast,
      curve: Curves.easeOut,
      height: height,
      margin: EdgeInsets.only(top: lipDepth - depth, bottom: depth),
      decoration: ShapeDecoration(
        shape: StadiumBorder(
          side: BorderSide(
            color: primary ? PlayfulColors.lip : PlayfulColors.accent,
            width: primary ? 2.5 : 2,
          ),
        ),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: primary
              ? const [Color(0xFF9B6BFF), Color(0xFF6B3FE6)]
              : const [Colors.white, Color(0xFFF1EBFF)],
        ),
      ),
      child: Stack(
        children: [
          // Glossy highlight across the top, like the logo lettering.
          Positioned(
            left: 18,
            right: 18,
            top: 4,
            height: height * 0.34,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: AppRadius.pill,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withValues(alpha: primary ? 0.35 : 0.9),
                    Colors.white.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
          Center(
            child: _content(
              iconColor: primary ? Colors.white : PlayfulColors.accent,
              textColor: foreground,
              textShadow: primary ? PlayfulColors.lip : Colors.white,
            ),
          ),
        ],
      ),
    );

    return Semantics(
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _setPressed(true),
        onTapUp: (_) => _setPressed(false),
        onTapCancel: () => _setPressed(false),
        onTap: _handleTap,
        child: Container(
          height: height + lipDepth,
          width: double.infinity,
          decoration: ShapeDecoration(
            shape: const StadiumBorder(),
            color: lipColor,
            shadows: [
              BoxShadow(
                color: PlayfulColors.accent.withValues(
                  alpha: primary ? 0.35 : 0.15,
                ),
                blurRadius: _pressed ? 8 : 18,
                offset: Offset(0, _pressed ? 3 : 10),
              ),
            ],
          ),
          alignment: Alignment.topCenter,
          child: face,
        ),
      ),
    );
  }

  /// Frosted, greyed-out pill shown until the action becomes available.
  Widget _disabled() => Semantics(
    button: true,
    enabled: false,
    child: Container(
      height: widget.primary ? 62 : 54,
      width: double.infinity,
      alignment: Alignment.center,
      decoration: ShapeDecoration(
        shape: StadiumBorder(
          side: BorderSide(color: Colors.white.withValues(alpha: 0.7)),
        ),
        color: Colors.white.withValues(alpha: 0.4),
      ),
      child: _content(
        iconColor: PlayfulColors.soft,
        textColor: PlayfulColors.soft,
      ),
    ),
  );

  Widget _content({
    required Color iconColor,
    required Color textColor,
    Color? textShadow,
  }) {
    final primary = widget.primary;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            widget.icon,
            size: primary ? 30 : 26,
            color: iconColor,
            shadows: textShadow == PlayfulColors.lip
                ? const [Shadow(color: PlayfulColors.lip, offset: Offset(0, 2))]
                : null,
          ),
          SizedBox(width: primary ? 14 : 12),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                widget.label,
                style: TextStyle(
                  fontSize: primary ? 22 : 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                  color: textColor,
                  shadows: textShadow == null
                      ? null
                      : [Shadow(color: textShadow, offset: const Offset(0, 2))],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// White circular icon button used for back / secondary top-bar actions.
class RoundIconButton extends StatelessWidget {
  const RoundIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.white,
        shape: const CircleBorder(),
        elevation: 0,
        shadowColor: Colors.transparent,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: Ink(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: PlayfulColors.accent.withValues(alpha: 0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: PlayfulColors.accentDeep, size: 26),
          ),
        ),
      ),
    );
  }
}

/// Two-line bubbly title in the logo's style: white top line, yellow bottom
/// line, both with a thick purple outline and a sparkle on each side.
class BubbleTitle extends StatelessWidget {
  const BubbleTitle({
    super.key,
    required this.top,
    required this.bottom,
    this.semanticsLabel,
  });

  final String top;
  final String bottom;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      label: semanticsLabel ?? '$top $bottom',
      child: ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 14),
              child: Sparks(color: PlayfulColors.yellow, mirrored: true),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _OutlinedWord(
                      top,
                      size: 38,
                      fill: const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.white, Color(0xFFEDE7FF)],
                      ),
                    ),
                    Transform.translate(
                      offset: const Offset(0, -8),
                      child: _OutlinedWord(
                        bottom,
                        size: 46,
                        fill: const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0xFFFFE27A), Color(0xFFFFB81C)],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 6),
            const Padding(
              padding: EdgeInsets.only(top: 14),
              child: Sparks(color: PlayfulColors.yellow),
            ),
          ],
        ),
      ),
    );
  }
}

class _OutlinedWord extends StatelessWidget {
  const _OutlinedWord(this.text, {required this.size, required this.fill});

  final String text;
  final double size;
  final Gradient fill;

  @override
  Widget build(BuildContext context) {
    TextStyle style(Paint paint, {List<Shadow>? shadows}) => TextStyle(
      fontSize: size,
      fontWeight: FontWeight.w900,
      letterSpacing: 1,
      height: 1.05,
      foreground: paint,
      shadows: shadows,
    );
    return Stack(
      children: [
        // Drop shadow + deep edge underneath.
        Transform.translate(
          offset: const Offset(0, 5),
          child: Text(
            text,
            style: style(
              Paint()
                ..style = PaintingStyle.stroke
                ..strokeWidth = size * 0.26
                ..strokeJoin = StrokeJoin.round
                ..color = PlayfulColors.lip,
              shadows: [
                Shadow(
                  color: PlayfulColors.accent.withValues(alpha: 0.35),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
          ),
        ),
        Text(
          text,
          style: style(
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = size * 0.26
              ..strokeJoin = StrokeJoin.round
              ..color = PlayfulColors.accentDeep,
          ),
        ),
        ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: fill.createShader,
          child: Text(text, style: style(Paint()..color = Colors.white)),
        ),
      ],
    );
  }
}

/// Little burst of two rounded dashes.
class Sparks extends StatelessWidget {
  const Sparks({super.key, required this.color, this.mirrored = false});

  final Color color;
  final bool mirrored;

  @override
  Widget build(BuildContext context) => Transform.flip(
    flipX: mirrored,
    child: CustomPaint(
      size: const Size(26, 30),
      painter: _SparksPainter(color),
    ),
  );
}

class _SparksPainter extends CustomPainter {
  _SparksPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(4, 10), const Offset(12, 3), paint);
    canvas.drawLine(const Offset(8, 19), const Offset(22, 14), paint);
  }

  @override
  bool shouldRepaint(_SparksPainter old) => old.color != color;
}

/// Paints the soft lavender backdrop: blobs, faded question marks, stars,
/// spark dashes and purple waves along the bottom.
class PlayfulBackground extends StatelessWidget {
  const PlayfulBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) =>
      CustomPaint(painter: _PlayfulBackgroundPainter(), child: child);
}

class _PlayfulBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFEEE6FD), Color(0xFFF6F2FE), Color(0xFFEDE5FC)],
        ).createShader(Offset.zero & size),
    );

    final blob = Paint()
      ..color = const Color(0xFFDCCFF8).withValues(alpha: 0.6);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.02, h * 0.1),
        width: w * 0.9,
        height: h * 0.2,
      ),
      blob,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 1.02, h * 0.2),
        width: w * 0.4,
        height: h * 0.14,
      ),
      blob,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(-w * 0.02, h * 0.42),
        width: w * 0.45,
        height: h * 0.2,
      ),
      blob,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 1.0, h * 0.44),
        width: w * 0.62,
        height: h * 0.18,
      ),
      blob,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.98, h * 0.74),
        width: w * 0.42,
        height: h * 0.24,
      ),
      blob,
    );

    final decor = PlayfulColors.decor.withValues(alpha: 0.75);
    _question(canvas, Offset(w * 0.84, h * 0.1), h * 0.13, decor);
    _question(canvas, Offset(w * 0.1, h * 0.2), h * 0.06, decor);
    _question(canvas, Offset(w * 0.15, h * 0.5), h * 0.12, decor);
    _question(canvas, Offset(w * 0.85, h * 0.49), h * 0.12, decor);
    _question(canvas, Offset(w * 0.24, h * 0.76), h * 0.1, decor);

    final star = Paint()
      ..color = const Color(0xFFB9A0F3).withValues(alpha: 0.8);
    for (final (x, y, r) in [
      (0.71, 0.09, 8.0),
      (0.83, 0.21, 9.0),
      (0.3, 0.43, 10.0),
      (0.88, 0.4, 9.0),
      (0.88, 0.57, 9.0),
      (0.84, 0.63, 10.0),
      (0.12, 0.7, 10.0),
      (0.35, 0.83, 10.0),
    ]) {
      _star(canvas, Offset(w * x, h * y), r, star);
    }

    final dot = Paint()..color = const Color(0xFFB9A0F3).withValues(alpha: 0.7);
    canvas.drawCircle(Offset(w * 0.7, h * 0.78), 7, dot);

    _dashes(canvas, Offset(w * 0.12, h * 0.585), PlayfulColors.yellow, -0.9);
    _dashes(canvas, Offset(w * 0.87, h * 0.815), const Color(0xFF7B55EE), -0.9);

    // Waves.
    final wave1 = Path()
      ..moveTo(0, h * 0.8)
      ..cubicTo(w * 0.3, h * 0.76, w * 0.55, h * 0.86, w, h * 0.8)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(
      wave1,
      Paint()..color = const Color(0xFFDDD0F8).withValues(alpha: 0.8),
    );
    final wave2 = Path()
      ..moveTo(0, h * 0.86)
      ..cubicTo(w * 0.35, h * 0.82, w * 0.6, h * 0.92, w, h * 0.85)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(
      wave2,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [const Color(0xFFCDB9F6), const Color(0xFFB195F0)],
        ).createShader(Rect.fromLTRB(0, h * 0.82, w, h)),
    );
  }

  void _question(Canvas canvas, Offset center, double size, Color color) {
    final painter = TextPainter(
      text: TextSpan(
        text: '?',
        style: TextStyle(
          fontSize: size,
          fontWeight: FontWeight.w900,
          color: color,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(
      canvas,
      center - Offset(painter.width / 2, painter.height / 2),
    );
  }

  void _star(Canvas canvas, Offset c, double r, Paint paint) {
    final path = Path();
    for (var i = 0; i < 10; i++) {
      final radius = i.isEven ? r : r * 0.5;
      final a = -pi / 2 + i * pi / 5;
      final p = c + Offset(cos(a) * radius, sin(a) * radius);
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    path.close();
    canvas.drawPath(
      path,
      Paint()
        ..color = paint.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.35
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.drawPath(path, paint);
  }

  void _dashes(Canvas canvas, Offset o, Color color, double angle) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    canvas.save();
    canvas.translate(o.dx, o.dy);
    canvas.rotate(angle);
    canvas.drawLine(const Offset(0, 0), const Offset(0, 16), paint);
    canvas.drawLine(const Offset(14, 6), const Offset(14, 20), paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_PlayfulBackgroundPainter old) => false;
}

/// Masquerade mask glyph (no matching Material icon). Sized and coloured
/// from the ambient [IconTheme].
class MaskIcon extends StatelessWidget {
  const MaskIcon({super.key, this.size, this.color});

  final double? size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = IconTheme.of(context);
    final s = size ?? theme.size ?? 24;
    return CustomPaint(
      size: Size.square(s),
      painter: _MaskPainter(color ?? theme.color ?? PlayfulColors.accent),
    );
  }
}

class _MaskPainter extends CustomPainter {
  _MaskPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 24);
    final path = Path()
      ..fillType = PathFillType.evenOdd
      ..moveTo(1.5, 9)
      ..cubicTo(1.5, 6.6, 4, 6, 7, 6.5)
      ..cubicTo(9, 6.8, 10.5, 7.8, 12, 7.8)
      ..cubicTo(13.5, 7.8, 15, 6.8, 17, 6.5)
      ..cubicTo(20, 6, 22.5, 6.6, 22.5, 9)
      ..cubicTo(22.5, 13.5, 20, 17, 16.5, 17)
      ..cubicTo(14.5, 17, 13.5, 15, 12, 15)
      ..cubicTo(10.5, 15, 9.5, 17, 7.5, 17)
      ..cubicTo(4, 17, 1.5, 13.5, 1.5, 9)
      ..close()
      ..addOval(
        Rect.fromCenter(center: const Offset(7.4, 11), width: 5, height: 3),
      )
      ..addOval(
        Rect.fromCenter(center: const Offset(16.6, 11), width: 5, height: 3),
      );
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_MaskPainter old) => old.color != color;
}

/// Small-caps section heading with a leading purple icon.
class SectionLabel extends StatelessWidget {
  const SectionLabel({super.key, required this.icon, required this.title});

  final Widget icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 10),
      child: Row(
        children: [
          IconTheme(
            data: const IconThemeData(color: PlayfulColors.accent, size: 28),
            child: icon,
          ),
          const SizedBox(width: 10),
          Semantics(
            header: true,
            child: Text(
              title.toUpperCase(),
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.4,
                color: PlayfulColors.accent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Frosted white rounded panel used for grouped settings.
class FrostedCard extends StatelessWidget {
  const FrostedCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white),
        boxShadow: [
          BoxShadow(
            color: PlayfulColors.accent.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}
