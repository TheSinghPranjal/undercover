import 'dart:math';

import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';

/// One-shot celebratory confetti. Purely decorative.
class ConfettiBurst extends StatefulWidget {
  const ConfettiBurst({super.key, this.enabled = true});

  final bool enabled;

  @override
  State<ConfettiBurst> createState() => _ConfettiBurstState();
}

class _ConfettiBurstState extends State<ConfettiBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_Piece> _pieces = _Piece.generate(70);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    if (widget.enabled) _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return const SizedBox.shrink();
    return IgnorePointer(
      child: ExcludeSemantics(
        child: RepaintBoundary(
          child: CustomPaint(
            size: Size.infinite,
            painter: _ConfettiPainter(_pieces, _controller),
          ),
        ),
      ),
    );
  }
}

class _Piece {
  _Piece(this.angle, this.speed, this.spin, this.color, this.size);

  final double angle, speed, spin, size;
  final Color color;

  static const _colors = [
    AppColors.violet,
    AppColors.electricBlue,
    AppColors.warmYellow,
    AppColors.coral,
    AppColors.mint,
  ];

  static List<_Piece> generate(int n) {
    final r = Random();
    return List.generate(
      n,
      (_) => _Piece(
        -pi / 2 + (r.nextDouble() - 0.5) * pi * 0.9,
        0.5 + r.nextDouble() * 0.7,
        (r.nextDouble() - 0.5) * 12,
        _colors[r.nextInt(_colors.length)],
        6 + r.nextDouble() * 6,
      ),
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.pieces, this.animation) : super(repaint: animation);

  final List<_Piece> pieces;
  final Animation<double> animation;

  @override
  void paint(Canvas canvas, Size size) {
    final t = animation.value;
    if (t == 0 || t == 1) return;
    final origin = Offset(size.width / 2, size.height * 0.35);
    final reach = size.shortestSide * 0.9;
    final paint = Paint();
    for (final p in pieces) {
      final d = reach * p.speed * Curves.easeOut.transform(t);
      final gravity = 600 * t * t;
      final pos = origin + Offset(cos(p.angle) * d, sin(p.angle) * d + gravity);
      paint.color = p.color.withValues(alpha: (1 - t).clamp(0, 1));
      canvas.save();
      canvas.translate(pos.dx, pos.dy);
      canvas.rotate(p.spin * t);
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset.zero,
          width: p.size,
          height: p.size * 0.5,
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => false;
}
