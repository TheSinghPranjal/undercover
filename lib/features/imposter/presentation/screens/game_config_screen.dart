import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/router.dart';
import '../../../../app/theme/app_tokens.dart';
import '../../../../core/widgets/game_background.dart';
import '../providers/providers.dart';
import '../widgets/difficulty_picker.dart';
import '../widgets/game_button.dart';
import '../widgets/imposter_stepper.dart';
import '../widgets/section_card.dart';
import 'round_flow_screen.dart';

class GameConfigScreen extends ConsumerWidget {
  const GameConfigScreen({super.key});

  void _start(BuildContext context, WidgetRef ref) {
    ref.read(gameControllerProvider.notifier).startRound();
    Navigator.of(
      context,
    ).push(GameRoute(builder: (_) => const RoundFlowScreen()));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final muted = scheme.onSurface.withValues(alpha: 0.7);
    final settings = ref.watch(gameSettingsProvider);
    final settingsController = ref.read(gameSettingsProvider.notifier);
    final playerCount = ref.watch(playersProvider.select((p) => p.length));
    final imposters = ref.watch(effectiveImposterCountProvider);
    final maxImposters = ref.watch(maxImpostersProvider);
    final error = ref.watch(
      gameControllerProvider.select((s) => s.errorMessage),
    );

    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) ref.read(gameControllerProvider.notifier).goToPlayerSetup();
      },
      child: Scaffold(
        appBar: AppBar(),
        extendBodyBehindAppBar: true,
        body: GameBackground(
          child: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.gutter,
                      kToolbarHeight - AppSpacing.md,
                      AppSpacing.gutter,
                      AppSpacing.md,
                    ),
                    children: [
                      Semantics(
                        header: true,
                        child: Text(
                          'READY TO PLAY?',
                          textAlign: TextAlign.center,
                          style: text.displaySmall,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Set the rules for this round.',
                        textAlign: TextAlign.center,
                        style: text.bodyLarge?.copyWith(color: muted),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Center(
                        child: ActionChip(
                          avatar: const Icon(Icons.group_rounded, size: 18),
                          label: Text('$playerCount players · Edit'),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ),
                      if (error != null) ...[
                        const SizedBox(height: AppSpacing.md),
                        MaterialBanner(
                          content: Text(error),
                          leading: const Icon(Icons.error_outline_rounded),
                          actions: [
                            TextButton(
                              onPressed: ref
                                  .read(gameControllerProvider.notifier)
                                  .clearError,
                              child: const Text('OK'),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: AppSpacing.lg),
                      SectionCard(
                        title: 'Difficulty',
                        child: DifficultyPicker(
                          value: settings.difficulty,
                          onChanged: settingsController.setDifficulty,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      SectionCard(
                        title: 'Imposters',
                        child: Column(
                          children: [
                            ImposterStepper(
                              value: imposters,
                              max: maxImposters,
                              onChanged: settingsController.setImposterCount,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              'Maximum imposters for $playerCount players: $maxImposters',
                              textAlign: TextAlign.center,
                              style: text.bodySmall?.copyWith(color: muted),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      SectionCard(
                        title: 'Imposter hint',
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.xs,
                        ),
                        child: SwitchListTile.adaptive(
                          contentPadding: EdgeInsets.zero,
                          value: settings.showHint,
                          onChanged: settingsController.setShowHint,
                          title: Text(
                            'Show hint to imposter',
                            style: text.titleMedium,
                          ),
                          subtitle: Text(
                            'Hints give the imposter a tiny clue without revealing the word.',
                            style: text.bodySmall?.copyWith(color: muted),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.gutter,
                    0,
                    AppSpacing.gutter,
                    AppSpacing.md,
                  ),
                  child: Column(
                    children: [
                      GameButton(
                        label: 'PASS THE PHONE',
                        icon: Icons.play_arrow_rounded,
                        onPressed: () => _start(context, ref),
                      ),
                      GameButton(
                        label: 'Edit players',
                        variant: GameButtonVariant.ghost,
                        onPressed: () => Navigator.of(context).pop(),
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
}
