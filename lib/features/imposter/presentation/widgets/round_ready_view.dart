import 'dart:math';

import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../app/theme/app_tokens.dart';
import '../../domain/entities/player.dart';
import 'confetti_burst.dart';
import 'game_button.dart';

/// Hand-off: every card is seen, announce who gives the first clue.
///
/// Drawn over [backgroundAsset] (a bright illustration), so it always uses
/// the light theme regardless of the app's brightness. The artwork's
/// characters sit mid-screen; the content leaves a gap for them between the
/// header and the footer.
class RoundReadyView extends StatelessWidget {
  const RoundReadyView({
    super.key,
    required this.startingPlayer,
    required this.animationsEnabled,
    required this.onNextRound,
    required this.onChangeSettings,
  });

  static const backgroundAsset = 'assets/images/round_ready_background.webp';

  final Player startingPlayer;
  final bool animationsEnabled;
  final VoidCallback onNextRound;
  final VoidCallback onChangeSettings;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.light,
      child: Builder(
        builder: (context) => Stack(
          children: [
            Positioned.fill(child: ConfettiBurst(enabled: animationsEnabled)),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.gutter,
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // Short phones: drop the decorative emoji so the
                  // characters still peek through between the cards.
                  final compact = constraints.maxHeight < 640;
                  return SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: IntrinsicHeight(
                        child: Column(
                          children: [
                            _Header(compact: compact),
                            const SizedBox(height: AppSpacing.md),
                            _TicketCard(
                              player: startingPlayer,
                              animate: animationsEnabled,
                              compact: compact,
                            ),
                            // Room for the characters in the artwork.
                            const Spacer(),
                            const SizedBox(height: AppSpacing.lg),
                            const _NoteCard(),
                            const SizedBox(height: AppSpacing.md),
                            GameButton(
                              label: 'AGAIN! 🔥',
                              icon: Icons.refresh_rounded,
                              variant: GameButtonVariant.hero,
                              onPressed: onNextRound,
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            GameButton(
                              label: 'Change settings',
                              variant: GameButtonVariant.ghost,
                              onPressed: onChangeSettings,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

const _paper = Color(0xFFFFF8EC);
const _muted = Color(0xFF4A4263);

class _Header extends StatelessWidget {
  const _Header({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      children: [
        Text('🎉', style: TextStyle(fontSize: compact ? 36 : 48)),
        Text(
          "EVERYONE'S READY",
          textAlign: TextAlign.center,
          style: text.labelLarge?.copyWith(
            color: AppColors.violet,
            letterSpacing: 2.4,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: [
            const _Sparks(),
            Expanded(
              child: Semantics(
                header: true,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text.rich(
                    const TextSpan(
                      children: [
                        TextSpan(text: 'Let the '),
                        TextSpan(
                          text: 'chaos',
                          style: TextStyle(color: AppColors.violet),
                        ),
                        TextSpan(text: ' begin!'),
                      ],
                    ),
                    textAlign: TextAlign.center,
                    style: text.displaySmall?.copyWith(
                      color: AppColors.ink,
                      letterSpacing: -0.8,
                      shadows: const [
                        Shadow(color: Colors.white70, blurRadius: 12),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const _Sparks(mirrored: true),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Secret words are locked in.',
          textAlign: TextAlign.center,
          style: text.bodyLarge?.copyWith(color: _muted),
        ),
      ],
    );
  }
}

/// Cream "ticket" with a dashed inner border announcing the first speaker.
class _TicketCard extends StatelessWidget {
  const _TicketCard({
    required this.player,
    required this.animate,
    required this.compact,
  });

  final Player player;
  final bool animate;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Semantics(
      label: 'First clue goes to ${player.name}',
      excludeSemantics: true,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: animate ? 0.6 : 1, end: 1),
        duration: AppDurations.slow,
        curve: Curves.elasticOut,
        builder: (context, scale, child) =>
            Transform.scale(scale: scale, child: child),
        child: Transform.rotate(
          angle: -0.015,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: _paper.withValues(alpha: 0.94),
              borderRadius: AppRadius.card,
              boxShadow: AppShadows.soft(AppColors.ink),
            ),
            child: CustomPaint(
              painter: const _DashedBorderPainter(
                color: Color(0xFFE2D3BA),
                inset: 8,
                radius: 18,
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.md,
                  AppSpacing.md,
                  AppSpacing.lg,
                ),
                child: Column(
                  children: [
                    if (!compact)
                      const Text('🗣️', style: TextStyle(fontSize: 30)),
                    Text(
                      'FIRST CLUE GOES TO',
                      style: text.labelMedium?.copyWith(
                        color: AppColors.violet,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        const _Sparks(size: 22),
                        Expanded(
                          child: _NamePill(name: player.name, animate: animate),
                        ),
                        const _Sparks(size: 22, mirrored: true),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Yellow pill holding "`name` starts!", gently breathing.
class _NamePill extends StatefulWidget {
  const _NamePill({required this.name, required this.animate});

  final String name;
  final bool animate;

  @override
  State<_NamePill> createState() => _NamePillState();
}

class _NamePillState extends State<_NamePill>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );

  @override
  void initState() {
    super.initState();
    if (widget.animate) _pulse.repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, child) => Transform.scale(
        scale: 1 + 0.03 * _pulse.value,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: AppRadius.pill,
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFFFDC6E), AppColors.warmYellow],
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.warmYellow.withValues(
                  alpha: 0.35 + 0.25 * _pulse.value,
                ),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: child,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm + 2,
        ),
        child: Text(
          '${widget.name} starts!',
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: text.headlineLarge?.copyWith(
            color: AppColors.ink,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

/// Paper note with the table talk instructions.
class _NoteCard extends StatelessWidget {
  const _NoteCard();

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Transform.rotate(
      angle: 0.01,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: _paper.withValues(alpha: 0.94),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(26),
            topRight: Radius.circular(14),
            bottomLeft: Radius.circular(12),
            bottomRight: Radius.circular(28),
          ),
          boxShadow: AppShadows.soft(AppColors.ink),
        ),
        child: Row(
          children: [
            const _Sparks(size: 18, color: Color(0xFF8C84A3)),
            Expanded(
              child: Column(
                children: [
                  Text(
                    'Give clues. Listen carefully.\nFind the imposter.',
                    textAlign: TextAlign.center,
                    style: text.titleMedium?.copyWith(color: AppColors.ink),
                  ),
                  const SizedBox(height: AppSpacing.xs + 2),
                  Text(
                    'Put the phone down and start talking!',
                    textAlign: TextAlign.center,
                    style: text.bodyMedium?.copyWith(color: _muted),
                  ),
                ],
              ),
            ),
            const _Sparks(size: 18, color: Color(0xFF8C84A3), mirrored: true),
          ],
        ),
      ),
    );
  }
}

/// Three short strokes bursting outwards, like a cartoon "ta-da".
class _Sparks extends StatelessWidget {
  const _Sparks({
    this.size = 28,
    this.color = AppColors.warmYellow,
    this.mirrored = false,
  });

  final double size;
  final Color color;
  final bool mirrored;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Transform.flip(
      flipX: mirrored,
      child: CustomPaint(
        size: Size(size, size * 1.4),
        painter: _SparksPainter(color),
      ),
    ),
  );
}

class _SparksPainter extends CustomPainter {
  const _SparksPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = size.width * 0.18
      ..strokeCap = StrokeCap.round;
    // Burst centre sits just right of the widget, towards the content.
    final origin = Offset(size.width * 1.1, size.height / 2);
    for (final angle in const [-0.6, 0.0, 0.6]) {
      final dir = Offset(-cos(angle), sin(angle));
      canvas.drawLine(
        origin + dir * size.width * 0.45,
        origin + dir * size.width * 0.95,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_SparksPainter old) => old.color != color;
}

class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({
    required this.color,
    required this.inset,
    required this.radius,
  });

  final Color color;
  final double inset;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          (Offset.zero & size).deflate(inset),
          Radius.circular(radius),
        ),
      );
    const dash = 7.0, gap = 5.0;
    for (final metric in path.computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += dash + gap) {
        canvas.drawPath(metric.extractPath(d, d + dash), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter old) =>
      old.color != color || old.inset != inset || old.radius != radius;
}
