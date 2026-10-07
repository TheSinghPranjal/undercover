import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/router.dart';
import '../../../../app/theme/app_tokens.dart';
import '../../../../core/widgets/game_background.dart';
import '../../domain/enums/app_theme_preference.dart';
import '../../domain/enums/difficulty.dart';
import '../../domain/services/game_rules.dart';
import '../providers/providers.dart';
import '../widgets/imposter_stepper.dart';
import '../widgets/labels.dart';
import '../widgets/section_card.dart';
import 'how_to_play_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _reset(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset settings?'),
        content: const Text('Everything goes back to the defaults.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('RESET'),
          ),
        ],
      ),
    );
    if (ok == true) await ref.read(gameSettingsProvider.notifier).reset();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(gameSettingsProvider);
    final c = ref.read(gameSettingsProvider.notifier);
    final text = Theme.of(context).textTheme;
    final muted = Theme.of(
      context,
    ).colorScheme.onSurface.withValues(alpha: 0.7);
    final playerCount = ref.watch(playersProvider.select((p) => p.length));
    final maxImposters = playerCount >= GameRules.minPlayers
        ? GameRules.maxImposters(playerCount)
        : GameRules.maxImposters(GameRules.maxPlayers);
    final imposters = s.imposterCount.clamp(1, maxImposters);

    Widget toggle(
      String title,
      String? subtitle,
      bool value,
      ValueChanged<bool> onChanged,
    ) => SwitchListTile.adaptive(
      contentPadding: EdgeInsets.zero,
      title: Text(title, style: text.titleMedium),
      subtitle: subtitle == null
          ? null
          : Text(subtitle, style: text.bodySmall?.copyWith(color: muted)),
      value: value,
      onChanged: onChanged,
    );

    const gap = SizedBox(height: AppSpacing.lg);
    return Scaffold(
      appBar: AppBar(title: const Text('SETTINGS')),
      extendBodyBehindAppBar: true,
      body: GameBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.gutter,
              kToolbarHeight,
              AppSpacing.gutter,
              AppSpacing.xl,
            ),
            children: [
              SectionCard(
                title: 'Game settings',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Difficulty', style: text.titleMedium),
                    const SizedBox(height: AppSpacing.sm),
                    SegmentedButton<Difficulty>(
                      showSelectedIcon: false,
                      segments: [
                        for (final d in Difficulty.values)
                          ButtonSegment(value: d, label: Text(d.label)),
                      ],
                      selected: {s.difficulty},
                      onSelectionChanged: (v) => c.setDifficulty(v.first),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Imposters', style: text.titleMedium),
                              Text(
                                'Up to 1 per 3 players.',
                                style: text.bodySmall?.copyWith(color: muted),
                              ),
                            ],
                          ),
                        ),
                        ImposterStepper(
                          value: imposters,
                          max: maxImposters,
                          onChanged: c.setImposterCount,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    toggle(
                      'Show hint to imposter',
                      'A tiny clue, never the word.',
                      s.showHint,
                      c.setShowHint,
                    ),
                    toggle(
                      'Allow duplicate names',
                      null,
                      s.allowDuplicateNames,
                      c.setAllowDuplicateNames,
                    ),
                  ],
                ),
              ),
              gap,
              SectionCard(
                title: 'Appearance',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Theme', style: text.titleMedium),
                    const SizedBox(height: AppSpacing.sm),
                    SegmentedButton<AppThemePreference>(
                      showSelectedIcon: false,
                      segments: const [
                        ButtonSegment(
                          value: AppThemePreference.system,
                          icon: Icon(Icons.brightness_auto_rounded),
                          label: Text('System'),
                        ),
                        ButtonSegment(
                          value: AppThemePreference.light,
                          icon: Icon(Icons.light_mode_rounded),
                          label: Text('Light'),
                        ),
                        ButtonSegment(
                          value: AppThemePreference.dark,
                          icon: Icon(Icons.dark_mode_rounded),
                          label: Text('Dark'),
                        ),
                      ],
                      selected: {s.theme},
                      onSelectionChanged: (v) => c.setTheme(v.first),
                    ),
                  ],
                ),
              ),
              gap,
              SectionCard(
                title: 'Gameplay',
                child: Column(
                  children: [
                    toggle(
                      'Haptic feedback',
                      null,
                      s.hapticsEnabled,
                      c.setHaptics,
                    ),
                    toggle(
                      'Animations',
                      null,
                      s.animationsEnabled,
                      c.setAnimations,
                    ),
                    toggle(
                      'Sound effects',
                      'Subtle taps. Never during a reveal.',
                      s.soundEnabled,
                      c.setSound,
                    ),
                    toggle(
                      'Tap to reveal',
                      'Easier than press & hold.',
                      s.tapToReveal,
                      c.setTapToReveal,
                    ),
                  ],
                ),
              ),
              gap,
              SectionCard(
                title: 'About',
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.help_outline_rounded),
                      title: const Text('How to play'),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => Navigator.of(context).push(
                        GameRoute(builder: (_) => const HowToPlayScreen()),
                      ),
                    ),
                    ListTile(
                      leading: const Icon(Icons.restart_alt_rounded),
                      title: const Text('Reset settings'),
                      onTap: () => _reset(context, ref),
                    ),
                  ],
                ),
              ),
              const _AdPrivacySection(),
              gap,
              Text(
                'Find the Imposter · 600 words · works offline',
                textAlign: TextAlign.center,
                style: text.bodySmall?.copyWith(color: muted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shown only when UMP requires a privacy-options entry point.
class _AdPrivacySection extends ConsumerStatefulWidget {
  const _AdPrivacySection();

  @override
  ConsumerState<_AdPrivacySection> createState() => _AdPrivacySectionState();
}

class _AdPrivacySectionState extends ConsumerState<_AdPrivacySection> {
  late final Future<bool> _required;

  @override
  void initState() {
    super.initState();
    _required = ref.read(adsServiceProvider).privacyOptionsRequired;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _required,
      builder: (context, snapshot) {
        if (snapshot.data != true) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(top: AppSpacing.lg),
          child: SectionCard(
            title: 'Ads',
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            child: ListTile(
              leading: const Icon(Icons.privacy_tip_outlined),
              title: const Text('Ad privacy choices'),
              subtitle: const Text('Manage how ads are personalized'),
              onTap: () {
                ref.read(adsServiceProvider).showPrivacyOptions();
              },
            ),
          ),
        );
      },
    );
  }
}
