import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_tokens.dart';
import '../../../../app/theme/game_colors.dart';
import '../../domain/entities/player_assignment.dart';
import '../../domain/services/game_rules.dart';
import '../providers/providers.dart';

/// A face-down card the current player presses and holds to flip.
///
/// The widget owns the hold progress, the 3D flip and the haptics. Whether
/// the card is face-up is decided by the parent through [isRevealed]:
/// the card calls [onRevealed] when a hold completes, and flips back when
/// [isRevealed] turns false, calling [onHidden] once it is face-down.
///
/// The secret face is only built while it is actually facing the viewer.
class SecretRevealCard extends ConsumerStatefulWidget {
  const SecretRevealCard({
    super.key,
    required this.playerName,
    required this.assignment,
    required this.isRevealed,
    required this.onRevealed,
    this.onHoldStart,
    this.onHoldCancel,
    this.onHidden,
    this.tapToReveal = false,
    this.animationsEnabled = true,
    this.holdDuration = GameRules.revealHoldDuration,
  });

  final String playerName;

  /// Null while face-down; the parent only receives it once revealed.
  final PlayerAssignment? assignment;
  final bool isRevealed;
  final VoidCallback onRevealed;
  final VoidCallback? onHoldStart;
  final VoidCallback? onHoldCancel;
  final VoidCallback? onHidden;
  final bool tapToReveal;
  final bool animationsEnabled;
  final Duration holdDuration;

  @override
  ConsumerState<SecretRevealCard> createState() => _SecretRevealCardState();
}

class _SecretRevealCardState extends ConsumerState<SecretRevealCard>
    with TickerProviderStateMixin {
  late final AnimationController _hold =
      AnimationController(vsync: this, duration: widget.holdDuration)
        ..addListener(_onHoldTick)
        ..addStatusListener(_onHoldStatus);

  late final AnimationController _flip = AnimationController(
    vsync: this,
    duration: AppDurations.flip,
    value: widget.isRevealed ? 1 : 0,
  );

  late final Animation<double> _flipCurve = CurvedAnimation(
    parent: _flip,
    curve: Curves.easeInOutCubic,
  );

  bool _halfwayBuzzed = false;
  bool _holding = false;

  bool get _tapMode =>
      widget.tapToReveal || MediaQuery.of(context).accessibleNavigation;

  @override
  void didUpdateWidget(SecretRevealCard old) {
    super.didUpdateWidget(old);
    if (widget.isRevealed && !old.isRevealed) {
      _showFace();
    } else if (!widget.isRevealed && old.isRevealed) {
      _hideFace();
    }
  }

  @override
  void dispose() {
    _hold.dispose();
    _flip.dispose();
    super.dispose();
  }

  // ----------------------------------------------------------------- hold

  void _onPointerDown(PointerDownEvent _) {
    if (widget.isRevealed || _tapMode || _holding) return;
    _holding = true;
    _halfwayBuzzed = false;
    ref.read(hapticsProvider).light();
    widget.onHoldStart?.call();
    _hold.forward(from: 0);
  }

  void _onPointerUp(PointerEvent _) {
    if (!_holding) return;
    _holding = false;
    if (_hold.status != AnimationStatus.completed) {
      _hold.animateBack(0, duration: AppDurations.fast);
      widget.onHoldCancel?.call();
    }
  }

  void _onHoldTick() {
    if (!_halfwayBuzzed && _hold.value >= 0.5) {
      _halfwayBuzzed = true;
      ref.read(hapticsProvider).selection();
    }
  }

  void _onHoldStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed && _holding) {
      _holding = false;
      _reveal();
    }
  }

  void _reveal() {
    if (widget.isRevealed) return;
    ref.read(hapticsProvider).medium();
    widget.onRevealed();
  }

  // ----------------------------------------------------------------- flip

  Future<void> _showFace() async {
    if (!widget.animationsEnabled) {
      _flip.value = 1;
    } else {
      await _flip.forward().orCancel.catchError((_) {});
    }
    if (mounted) ref.read(hapticsProvider).selection();
  }

  Future<void> _hideFace() async {
    _hold.value = 0;
    if (!widget.animationsEnabled) {
      _flip.value = 0;
      // Let the face-down frame render before the parent moves on.
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onHidden?.call();
      });
      return;
    }
    await _flip.reverse().orCancel.catchError((_) {});
    if (mounted && !widget.isRevealed) widget.onHidden?.call();
  }

  // ----------------------------------------------------------------- build

  @override
  Widget build(BuildContext context) {
    final tapMode = _tapMode;
    return Semantics(
      container: true,
      button: !widget.isRevealed,
      label: widget.isRevealed ? null : 'Secret card for ${widget.playerName}',
      hint: widget.isRevealed
          ? null
          : (tapMode ? 'Double tap to reveal' : 'Press and hold to reveal'),
      onTap: widget.isRevealed ? null : _reveal,
      onLongPress: widget.isRevealed ? null : _reveal,
      child: Listener(
        onPointerDown: _onPointerDown,
        onPointerUp: _onPointerUp,
        onPointerCancel: _onPointerUp,
        child: GestureDetector(
          onTap: tapMode && !widget.isRevealed ? _reveal : null,
          child: MediaQuery.withClampedTextScaling(
            maxScaleFactor: 1.4,
            child: AnimatedBuilder(
              animation: Listenable.merge([_flipCurve, _hold]),
              builder: (context, _) {
                final t = _flipCurve.value;
                final showFace = t >= 0.5;
                // Slight squash while holding, for a physical feel.
                final press = 1 - 0.04 * _hold.value;
                return Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.0012)
                    ..rotateY(t * pi)
                    ..scaleByDouble(press, press, 1, 1),
                  child: showFace
                      ? Transform(
                          alignment: Alignment.center,
                          transform: Matrix4.rotationY(pi),
                          child: _CardFace(assignment: widget.assignment),
                        )
                      : _CardBack(progress: _hold.value, tapMode: tapMode),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _CardShell extends StatelessWidget {
  const _CardShell({required this.gradient, required this.child});

  final List<Color> gradient;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(Radius.circular(AppRadius.xl)),
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: AppShadows.glow(gradient.first),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.25),
          width: 2,
        ),
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: child,
    );
  }
}

/// Face-down side: lock, hold progress ring, instructions.
class _CardBack extends StatelessWidget {
  const _CardBack({required this.progress, required this.tapMode});

  final double progress;
  final bool tapMode;

  @override
  Widget build(BuildContext context) {
    final colors = GameColors.of(context);
    final text = Theme.of(context).textTheme;
    final onCard = colors.onCard;
    return _CardShell(
      gradient: colors.cardBack,
      child: Stack(
        children: [
          Positioned.fill(
            child: ExcludeSemantics(
              child: CustomPaint(painter: _PatternPainter(onCard)),
            ),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 112,
                  height: 112,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox.expand(
                        child: CircularProgressIndicator(
                          value: progress,
                          strokeWidth: 7,
                          strokeCap: StrokeCap.round,
                          color: colors.highlight,
                          backgroundColor: onCard.withValues(alpha: 0.18),
                        ),
                      ),
                      Icon(
                        progress > 0
                            ? Icons.lock_open_rounded
                            : Icons.lock_rounded,
                        size: 48,
                        color: onCard,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'SECRET CARD',
                  textAlign: TextAlign.center,
                  style: text.headlineSmall?.copyWith(
                    color: onCard,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  tapMode ? 'Tap to reveal' : 'Press & hold to reveal',
                  textAlign: TextAlign.center,
                  style: text.bodyLarge?.copyWith(
                    color: onCard.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Face-up side: the secret word, or the imposter reveal (+ optional hint).
class _CardFace extends StatelessWidget {
  const _CardFace({required this.assignment});

  final PlayerAssignment? assignment;

  @override
  Widget build(BuildContext context) {
    final colors = GameColors.of(context);
    final text = Theme.of(context).textTheme;
    final a = assignment;
    if (a == null) {
      return _CardShell(
        gradient: colors.cardBack,
        child: const SizedBox.expand(),
      );
    }
    final onCard = colors.onCard;
    final label = text.labelMedium?.copyWith(
      color: onCard.withValues(alpha: 0.85),
      letterSpacing: 2,
    );

    if (!a.isImposter) {
      return _CardShell(
        gradient: colors.civilianCard,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('YOUR SECRET WORD', textAlign: TextAlign.center, style: label),
            const SizedBox(height: AppSpacing.md),
            Semantics(
              label: 'Your secret word is ${a.word}',
              excludeSemantics: true,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  a.word!.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: text.displayLarge?.copyWith(color: onCard),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            const Text(
              '🤫',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 34),
            ),
          ],
        ),
      );
    }

    return _CardShell(
      gradient: colors.imposterCard,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            '🚨',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 40),
          ),
          const SizedBox(height: AppSpacing.sm),
          Semantics(
            label: 'You are the imposter',
            excludeSemantics: true,
            child: Column(
              children: [
                Text('YOU ARE', textAlign: TextAlign.center, style: label),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    'THE IMPOSTER',
                    textAlign: TextAlign.center,
                    style: text.displaySmall?.copyWith(color: onCard),
                  ),
                ),
              ],
            ),
          ),
          if (a.hint != null) ...[
            const SizedBox(height: AppSpacing.lg),
            Semantics(
              label: 'Hint: ${a.hint}',
              excludeSemantics: true,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.18),
                  borderRadius: AppRadius.button,
                ),
                child: Column(
                  children: [
                    Text('HINT', style: label?.copyWith(color: colors.hint)),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        a.hint!.toUpperCase(),
                        style: text.headlineMedium?.copyWith(
                          color: colors.hint,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Subtle diagonal "?" pattern on the card back.
class _PatternPainter extends CustomPainter {
  _PatternPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.07)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    const step = 28.0;
    for (var x = -size.height; x < size.width; x += step) {
      canvas.drawLine(
        Offset(x, size.height),
        Offset(x + size.height, 0),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_PatternPainter old) => old.color != color;
}
