import 'dart:math';

import 'package:flutter/material.dart';

import '../../app/theme/game_colors.dart';

/// Brand gradient with optional slowly drifting cards and sparkles.
class GameBackground extends StatelessWidget {
  const GameBackground({
    super.key,
    required this.child,
    this.particles = false,
    this.animate = true,
  });

  final Widget child;
  final bool particles;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final colors = GameColors.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: colors.background,
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (particles)
            Positioned.fill(
              child: ExcludeSemantics(
                child: RepaintBoundary(
                  child: FloatingParticles(
                    color: colors.particle,
                    animate: animate,
                  ),
                ),
              ),
            ),
          child,
        ],
      ),
    );
  }
}

class FloatingParticles extends StatefulWidget {
  const FloatingParticles({
    super.key,
    required this.color,
    this.animate = true,
  });

  final Color color;
  final bool animate;

  @override
  State<FloatingParticles> createState() => _FloatingParticlesState();
}

class _FloatingParticlesState extends State<FloatingParticles>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 30),
  );
  late final List<_Particle> _particles = _Particle.generate(18);

  @override
  void initState() {
    super.initState();
    if (widget.animate) _controller.repeat();
  }

  @override
  void didUpdateWidget(FloatingParticles oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.animate) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: _ParticlePainter(_particles, _controller, widget.color),
  );
}

class _Particle {
  _Particle(
    this.x,
    this.y,
    this.size,
    this.speed,
    this.spin,
    this.isCard,
    this.opacity,
  );

  final double x, y, size, speed, spin, opacity;
  final bool isCard;

  static List<_Particle> generate(int n) {
    final r = Random(7);
    return List.generate(
      n,
      (i) => _Particle(
        r.nextDouble(),
        r.nextDouble(),
        8 + r.nextDouble() * 18,
        0.3 + r.nextDouble() * 0.7,
        (r.nextDouble() - 0.5) * 4,
        i.isEven,
        0.06 + r.nextDouble() * 0.12,
      ),
    );
  }
}

class _ParticlePainter extends CustomPainter {
  _ParticlePainter(this.particles, this.animation, this.color)
    : super(repaint: animation);

  final List<_Particle> particles;
  final Animation<double> animation;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final t = animation.value;
    final paint = Paint();
    for (final p in particles) {
      final y = ((p.y - t * p.speed) % 1.0) * (size.height + 60) - 30;
      final x = p.x * size.width + sin((t * 2 * pi * p.speed) + p.y * 6) * 18;
      paint.color = color.withValues(alpha: p.opacity);
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(t * 2 * pi * p.spin * 0.2 + p.x * 3);
      if (p.isCard) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset.zero,
              width: p.size,
              height: p.size * 1.35,
            ),
            Radius.circular(p.size * 0.2),
          ),
          paint,
        );
      } else {
        _drawSparkle(canvas, p.size * 0.6, paint);
      }
      canvas.restore();
    }
  }

  void _drawSparkle(Canvas canvas, double r, Paint paint) {
    final path = Path()
      ..moveTo(0, -r)
      ..quadraticBezierTo(0, 0, r, 0)
      ..quadraticBezierTo(0, 0, 0, r)
      ..quadraticBezierTo(0, 0, -r, 0)
      ..quadraticBezierTo(0, 0, 0, -r)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_ParticlePainter old) =>
      old.color != color || old.particles != particles;
}
