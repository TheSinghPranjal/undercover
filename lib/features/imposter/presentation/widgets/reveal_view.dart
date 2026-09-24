import 'dart:math';

import 'package:flutter/material.dart';

import '../../../../app/theme/app_tokens.dart';
import '../../domain/entities/player.dart';
import '../../domain/entities/player_assignment.dart';
import '../../domain/enums/game_phase.dart';
import 'game_button.dart';
import 'secret_reveal_card.dart';

/// One player's private moment with their card.
///
/// Receives only this player's data. Everything is passed in (rather than
/// read from providers) so that while this view animates out it keeps showing
/// its own – face-down – state and never the next player's.
class RevealView extends StatelessWidget {
  const RevealView({
    super.key,
    required this.player,
    required this.assignment,
    required this.phase,
    required this.isLastPlayer,
    required this.tapToReveal,
    required this.animationsEnabled,
    required this.onHoldStart,
    required this.onHoldCancel,
    required this.onRevealed,
    required this.onPass,
    required this.onHidden,
  });

  final Player player;
  final PlayerAssignment? assignment;
  final GamePhase phase;
  final bool isLastPlayer;
  final bool tapToReveal;
  final bool animationsEnabled;
  final VoidCallback onHoldStart;
  final VoidCallback onHoldCancel;
  final VoidCallback onRevealed;
  final VoidCallback onPass;
  final VoidCallback onHidden;

  bool get _isRevealed =>
      phase == GamePhase.revealed || phase == GamePhase.allPlayersRevealed;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final muted = scheme.onSurface.withValues(alpha: 0.72);

    final subtitle = _isRevealed
        ? 'Keep this secret 🤫'
        : 'Only ${player.name} should look 👀';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
      child: Column(
        children: [
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Your turn, ${player.name} 👀',
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: text.headlineMedium,
          ),
          const SizedBox(height: AppSpacing.xs),
          AnimatedSwitcher(
            duration: AppDurations.fast,
            child: Text(
              subtitle,
              key: ValueKey(subtitle),
              textAlign: TextAlign.center,
              style: text.bodyLarge?.copyWith(color: muted),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Expanded(
            child: LayoutBuilder(
              builder: (context, c) {
                const ratio = 0.72;
                final width = min(min(c.maxWidth, 380.0), c.maxHeight * ratio);
                return Center(
                  child: SizedBox(
                    width: width,
                    height: width / ratio,
                    child: SecretRevealCard(
                      playerName: player.name,
                      assignment: assignment,
                      isRevealed: _isRevealed,
                      tapToReveal: tapToReveal,
                      animationsEnabled: animationsEnabled,
                      onHoldStart: onHoldStart,
                      onHoldCancel: onHoldCancel,
                      onRevealed: onRevealed,
                      onHidden: onHidden,
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          AnimatedSize(
            duration: AppDurations.medium,
            curve: Curves.easeOutCubic,
            child: _footer(context, text, muted),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }

  Widget _footer(BuildContext context, TextTheme text, Color muted) {
    final lastPlayerText = Column(
      children: [
        Text(
          "Everyone has seen their role.",
          textAlign: TextAlign.center,
          style: text.titleMedium,
        ),
        Text(
          'Time to find the imposter.',
          textAlign: TextAlign.center,
          style: text.bodyMedium?.copyWith(color: muted),
        ),
      ],
    );

    switch (phase) {
      case GamePhase.readyToReveal:
      case GamePhase.revealing:
        return SizedBox(
          height: 58,
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  tapToReveal
                      ? Icons.touch_app_rounded
                      : Icons.fingerprint_rounded,
                  color: muted,
                ),
                const SizedBox(width: AppSpacing.sm),
                Flexible(
                  child: Text(
                    tapToReveal
                        ? 'Tap the card to reveal'
                        : 'Press & hold the card to reveal',
                    style: text.titleSmall?.copyWith(color: muted),
                  ),
                ),
              ],
            ),
          ),
        );
      case GamePhase.revealed:
      case GamePhase.allPlayersRevealed:
      case GamePhase.passing:
        final passing = phase == GamePhase.passing;
        return Column(
          children: [
            if (isLastPlayer)
              lastPlayerText
            else
              Text(
                assignment?.isImposter ?? false
                    ? 'Act natural.'
                    : 'Remember your word.',
                style: text.titleMedium?.copyWith(color: muted),
              ),
            const SizedBox(height: AppSpacing.md),
            GameButton(
              label: isLastPlayer ? 'START GAME' : 'PASS TO NEXT PLAYER',
              icon: isLastPlayer
                  ? Icons.play_arrow_rounded
                  : Icons.arrow_forward_rounded,
              onPressed: passing ? null : onPass,
            ),
          ],
        );
      default:
        return const SizedBox(height: 58);
    }
  }
}
