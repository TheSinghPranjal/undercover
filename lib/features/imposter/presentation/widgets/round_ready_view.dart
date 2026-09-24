import 'package:flutter/material.dart';

import '../../../../app/theme/app_tokens.dart';
import '../../../../app/theme/game_colors.dart';
import '../../domain/entities/player.dart';
import 'confetti_burst.dart';
import 'game_button.dart';

/// Hand-off: every card is seen, announce who gives the first clue.
class RoundReadyView extends StatelessWidget {
  const RoundReadyView({
    super.key,
    required this.startingPlayer,
    required this.animationsEnabled,
    required this.onNextRound,
    required this.onChangeSettings,
  });

  final Player startingPlayer;
  final bool animationsEnabled;
  final VoidCallback onNextRound;
  final VoidCallback onChangeSettings;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final muted = scheme.onSurface.withValues(alpha: 0.72);
    return Stack(
      children: [
        Positioned.fill(child: ConfettiBurst(enabled: animationsEnabled)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('🎉', style: TextStyle(fontSize: 56)),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          "EVERYONE'S READY",
                          textAlign: TextAlign.center,
                          style: text.labelLarge?.copyWith(
                            color: scheme.primary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Semantics(
                          header: true,
                          child: Text(
                            'Let the chaos begin!',
                            textAlign: TextAlign.center,
                            style: text.displaySmall,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Secret words are locked in.',
                          textAlign: TextAlign.center,
                          style: text.bodyLarge?.copyWith(color: muted),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        _Spotlight(
                          player: startingPlayer,
                          animate: animationsEnabled,
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        Text(
                          'Give clues. Listen carefully.\nFind the imposter.',
                          textAlign: TextAlign.center,
                          style: text.titleMedium,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'Put the phone down and start talking!',
                          textAlign: TextAlign.center,
                          style: text.bodyMedium?.copyWith(color: muted),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              GameButton(
                label: 'AGAIN! 🔥',
                icon: Icons.refresh_rounded,
                onPressed: onNextRound,
              ),
              const SizedBox(height: AppSpacing.xs),
              GameButton(
                label: 'Change settings',
                variant: GameButtonVariant.ghost,
                onPressed: onChangeSettings,
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
      ],
    );
  }
}

class _Spotlight extends StatefulWidget {
  const _Spotlight({required this.player, required this.animate});

  final Player player;
  final bool animate;

  @override
  State<_Spotlight> createState() => _SpotlightState();
}

class _SpotlightState extends State<_Spotlight>
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
    final colors = GameColors.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      label: 'First clue goes to ${widget.player.name}',
      excludeSemantics: true,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: widget.animate ? 0.6 : 1, end: 1),
        duration: AppDurations.slow,
        curve: Curves.elasticOut,
        builder: (context, scale, child) =>
            Transform.scale(scale: scale, child: child),
        child: AnimatedBuilder(
          animation: _pulse,
          builder: (context, child) => Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.lg,
            ),
            decoration: BoxDecoration(
              borderRadius: AppRadius.card,
              gradient: RadialGradient(
                colors: [
                  colors.highlight.withValues(alpha: 0.35 + 0.2 * _pulse.value),
                  colors.highlight.withValues(alpha: 0.0),
                ],
                radius: 0.9 + 0.2 * _pulse.value,
              ),
              border: Border.all(
                color: colors.highlight.withValues(alpha: 0.7),
                width: 2,
              ),
            ),
            child: child,
          ),
          child: Column(
            children: [
              const Text('🗣️', style: TextStyle(fontSize: 36)),
              Text(
                'FIRST CLUE GOES TO',
                style: text.labelMedium?.copyWith(color: scheme.primary),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '${widget.player.name} starts!',
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: text.displaySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
