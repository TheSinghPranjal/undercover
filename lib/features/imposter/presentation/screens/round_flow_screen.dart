import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../app/theme/app_tokens.dart';
import '../../../../core/ads/banner_gate.dart';
import '../../../../core/widgets/game_background.dart';
import '../../domain/enums/game_phase.dart';
import '../providers/providers.dart';
import '../providers/ui_providers.dart';
import '../widgets/exit_round_dialog.dart';
import '../widgets/pass_phone_view.dart';
import '../widgets/playful_ui.dart';
import '../widgets/reveal_view.dart';
import '../widgets/round_ready_view.dart';

/// Hosts the whole pass-the-phone loop for a round: pass → ready → reveal →
/// pass … → start game → starting player → next round.
///
/// Also the privacy guard: any time the app leaves the foreground a visible
/// secret is hidden and the player must confirm again.
class RoundFlowScreen extends ConsumerStatefulWidget {
  const RoundFlowScreen({super.key});

  @override
  ConsumerState<RoundFlowScreen> createState() => _RoundFlowScreenState();
}

class _RoundFlowScreenState extends ConsumerState<RoundFlowScreen>
    with WidgetsBindingObserver {
  bool _leaving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // The first hand-off screen appears immediately; avoid the art popping in.
    precacheImage(const AssetImage(PassPhoneView.suspectsAsset), context);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      ref.read(gameControllerProvider.notifier).hideCurrentPlayer();
    }
  }

  Future<void> _handleBack() async {
    final phase = ref.read(gamePhaseProvider);
    if (phase == GamePhase.generatingRound) return;
    if (phase.isRevealFlow && !await confirmExitRound(context)) return;
    _leave();
  }

  void _leave() {
    if (_leaving || !mounted) return;
    _leaving = true;
    ref.read(gameControllerProvider.notifier).exitRound();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    // Round generation failed – the configuration screen shows the error.
    ref.listen(gamePhaseProvider, (_, next) {
      if (next == GamePhase.configuration && !_leaving) {
        _leaving = true;
        Navigator.of(context).pop();
      }
    });

    final phase = ref.watch(gamePhaseProvider);
    final (position, total) = ref.watch(revealProgressProvider);
    final animate = animationsOn(context, ref);
    final onArt = phase == GamePhase.roundReady;
    // Hand-off screens use the light, illustrated lavender look.
    final onLavender =
        phase == GamePhase.passPhone || phase == GamePhase.privacyHidden;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final fade = animate ? AppDurations.medium : Duration.zero;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _handleBack();
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: onArt || (dark && !onLavender)
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
        child: Scaffold(
          body: GameBackground(
            child: Stack(
              fit: StackFit.expand,
              children: [
                Positioned(
                  left: 0,
                  top: 0,
                  width: 0,
                  height: 0,
                  child: SyncAnchoredBanner(
                    allowed: phase == GamePhase.roundReady,
                  ),
                ),
                IgnorePointer(
                  child: AnimatedOpacity(
                    opacity: onLavender ? 1 : 0,
                    duration: fade,
                    child: const PlayfulBackground(child: SizedBox.expand()),
                  ),
                ),
                // Kept in the tree (invisible) for the whole round so the
                // artwork is already decoded when the round-ready view appears.
                IgnorePointer(
                  child: AnimatedOpacity(
                    opacity: onArt ? 1 : 0,
                    duration: fade,
                    child: Image.asset(
                      RoundReadyView.backgroundAsset,
                      fit: BoxFit.cover,
                      excludeFromSemantics: true,
                    ),
                  ),
                ),
                SafeArea(
                  child: Column(
                    children: [
                      Theme(
                        data: onLavender ? AppTheme.light : Theme.of(context),
                        child: _TopBar(
                          phase: phase,
                          position: position,
                          total: total,
                          onArt: onArt,
                          onClose: _handleBack,
                        ),
                      ),
                      Expanded(
                        child: AnimatedSwitcher(
                          duration: animate
                              ? AppDurations.medium
                              : Duration.zero,
                          switchInCurve: Curves.easeOutCubic,
                          switchOutCurve: Curves.easeInCubic,
                          transitionBuilder: (child, animation) {
                            final incoming =
                                child.key == _viewKey(phase, position);
                            return FadeTransition(
                              opacity: animation,
                              child: SlideTransition(
                                position: Tween(
                                  begin: Offset(incoming ? 0.35 : -0.35, 0),
                                  end: Offset.zero,
                                ).animate(animation),
                                child: child,
                              ),
                            );
                          },
                          child: KeyedSubtree(
                            key: _viewKey(phase, position),
                            child: _buildPhase(phase, position, total, animate),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// One key per visual step. All reveal sub-phases share a key so the card
  /// keeps its state while it flips.
  ValueKey<String> _viewKey(GamePhase phase, int position) {
    final group = switch (phase) {
      GamePhase.readyToReveal ||
      GamePhase.revealing ||
      GamePhase.revealed ||
      GamePhase.passing ||
      GamePhase.allPlayersRevealed => 'reveal',
      _ => phase.name,
    };
    return ValueKey('$group-$position');
  }

  Widget _buildPhase(GamePhase phase, int position, int total, bool animate) {
    final controller = ref.read(gameControllerProvider.notifier);
    final player = ref.watch(currentPlayerProvider);

    switch (phase) {
      case GamePhase.passPhone:
        return PassPhoneView(
          player: player!,
          isFirst: position == 1,
          animate: animate,
          onReady: controller.confirmReady,
        );
      case GamePhase.privacyHidden:
        return PassPhoneView(
          player: player!,
          isFirst: false,
          emoji: '🙈',
          animate: animate,
          title: 'SCREEN HIDDEN FOR PRIVACY',
          message:
              'Hand the phone back to ${player.name}. Only they should tap below.',
          onReady: controller.confirmReady,
        );
      case GamePhase.readyToReveal:
      case GamePhase.revealing:
      case GamePhase.revealed:
      case GamePhase.passing:
      case GamePhase.allPlayersRevealed:
        return RevealView(
          player: player!,
          assignment: ref.watch(currentAssignmentProvider),
          phase: phase,
          isLastPlayer: position == total,
          tapToReveal: ref.watch(
            gameSettingsProvider.select((s) => s.tapToReveal),
          ),
          animationsEnabled: animate,
          onHoldStart: controller.beginHold,
          onHoldCancel: controller.cancelHold,
          onRevealed: controller.revealCurrentPlayer,
          onPass: controller.passToNextPlayer,
          onHidden: controller.completePass,
        );
      case GamePhase.roundReady:
        final starter = ref.watch(startingPlayerProvider);
        if (starter == null) return const SizedBox.shrink();
        return _RoundReady(
          child: RoundReadyView(
            startingPlayer: starter,
            animationsEnabled: animate,
            onNextRound: controller.startNextRound,
            onChangeSettings: _leave,
          ),
        );
      case GamePhase.generatingRound:
      case GamePhase.playerSetup:
      case GamePhase.configuration:
        return const _Shuffling();
    }
  }
}

/// Fires the success haptic once when the round-ready screen appears.
class _RoundReady extends ConsumerStatefulWidget {
  const _RoundReady({required this.child});

  final Widget child;

  @override
  ConsumerState<_RoundReady> createState() => _RoundReadyState();
}

class _RoundReadyState extends ConsumerState<_RoundReady> {
  @override
  void initState() {
    super.initState();
    ref.read(hapticsProvider).success();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.phase,
    required this.position,
    required this.total,
    required this.onArt,
    required this.onClose,
  });

  final GamePhase phase;
  final int position;
  final int total;

  /// Drawn over the round-ready artwork: use a frosted round close button.
  final bool onArt;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final showProgress = phase.isRevealFlow && total > 0;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Leave round',
            icon: const Icon(Icons.close_rounded),
            style: onArt
                ? IconButton.styleFrom(
                    backgroundColor: Colors.black.withValues(alpha: 0.28),
                    foregroundColor: Colors.white,
                  )
                : null,
            onPressed: onClose,
          ),
          Expanded(
            child: showProgress
                ? Semantics(
                    label: 'Player $position of $total',
                    excludeSemantics: true,
                    child: Column(
                      children: [
                        Text(
                          'PLAYER $position OF $total',
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        ClipRRect(
                          borderRadius: AppRadius.pill,
                          child: LinearProgressIndicator(
                            value: position / total,
                            minHeight: 6,
                            backgroundColor: scheme.primary.withValues(
                              alpha: 0.15,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }
}

class _Shuffling extends StatelessWidget {
  const _Shuffling();

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const CircularProgressIndicator(),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Shuffling the cards…',
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ],
    ),
  );
}
