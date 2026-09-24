import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/router.dart';
import '../../../../app/theme/app_tokens.dart';
import '../../domain/enums/difficulty.dart';
import '../providers/providers.dart';
import '../widgets/labels.dart';
import '../widgets/playful_ui.dart';
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
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark,
        child: Scaffold(
          backgroundColor: PlayfulColors.page,
          body: PlayfulBackground(
            child: SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(22, 8, 22, 16),
                      children: [
                        Stack(
                          children: [
                            Align(
                              alignment: Alignment.topLeft,
                              child: RoundIconButton(
                                icon: Icons.chevron_left_rounded,
                                tooltip: 'Back',
                                onPressed: () =>
                                    Navigator.of(context).maybePop(),
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.fromLTRB(36, 18, 36, 0),
                              child: Center(
                                child: BubbleTitle(
                                  top: 'READY TO',
                                  bottom: 'PLAY?',
                                  semanticsLabel: 'Ready to play?',
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Text(
                          'Set the rules for this round.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: PlayfulColors.muted,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Center(
                          child: _PlayersChip(
                            count: playerCount,
                            onTap: () => Navigator.of(context).maybePop(),
                          ),
                        ),
                        if (error != null) ...[
                          const SizedBox(height: 14),
                          _ErrorBanner(
                            message: error,
                            onDismiss: ref
                                .read(gameControllerProvider.notifier)
                                .clearError,
                          ),
                        ],
                        const SizedBox(height: 22),
                        const SectionLabel(
                          icon: Icon(Icons.sports_esports_rounded),
                          title: 'Difficulty',
                        ),
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            FrostedCard(
                              child: _DifficultyPicker(
                                value: settings.difficulty,
                                onChanged: settingsController.setDifficulty,
                              ),
                            ),
                            const Positioned(
                              left: -20,
                              top: 40,
                              child: Sparks(
                                color: Color(0xFF7B55EE),
                                mirrored: true,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 22),
                        const SectionLabel(
                          icon: MaskIcon(),
                          title: 'Imposters',
                        ),
                        FrostedCard(
                          padding: const EdgeInsets.fromLTRB(14, 20, 14, 16),
                          child: Column(
                            children: [
                              _ImposterStepper(
                                value: imposters,
                                max: maxImposters,
                                onChanged: settingsController.setImposterCount,
                              ),
                              const SizedBox(height: 14),
                              Text(
                                'Maximum imposters for $playerCount players: $maxImposters',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: PlayfulColors.muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 22),
                        const SectionLabel(
                          icon: Icon(Icons.contact_support_rounded),
                          title: 'Imposter hint',
                        ),
                        _HintToggle(
                          value: settings.showHint,
                          onChanged: settingsController.setShowHint,
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 4, 8, 16),
                    child: Row(
                      children: [
                        const Sparks(
                          color: PlayfulColors.yellow,
                          mirrored: true,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: PillButton(
                            label: 'PASS THE PHONE',
                            icon: Icons.play_arrow_rounded,
                            primary: true,
                            onPressed: () => _start(context, ref),
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Sparks(color: PlayfulColors.yellow),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PlayersChip extends StatelessWidget {
  const _PlayersChip({required this.count, required this.onTap});

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: Ink(
        decoration: ShapeDecoration(
          color: Colors.white,
          shape: const StadiumBorder(
            side: BorderSide(color: PlayfulColors.field, width: 1.5),
          ),
          shadows: [
            BoxShadow(
              color: PlayfulColors.accent.withValues(alpha: 0.12),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 18, 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.groups_rounded,
                  color: PlayfulColors.accent,
                  size: 28,
                ),
                const SizedBox(width: 16),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      '$count players · Edit',
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: PlayfulColors.ink,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: PlayfulColors.soft,
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message, required this.onDismiss});

  final String message;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    const coral = Color(0xFFE0304F);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 6, 6, 6),
      decoration: BoxDecoration(
        color: const Color(0xFFFFE9EE),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: coral.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: coral),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: PlayfulColors.ink,
              ),
            ),
          ),
          TextButton(onPressed: onDismiss, child: const Text('OK')),
        ],
      ),
    );
  }
}

class _DifficultyPicker extends StatelessWidget {
  const _DifficultyPicker({required this.value, required this.onChanged});

  final Difficulty value;
  final ValueChanged<Difficulty> onChanged;

  static Color _ball(Difficulty d) => switch (d) {
    Difficulty.easy => const Color(0xFF3CC13B),
    Difficulty.medium => const Color(0xFFFFC928),
    Difficulty.difficult => const Color(0xFFE0312B),
  };

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            for (final d in Difficulty.values) ...[
              if (d != Difficulty.values.first) const SizedBox(width: 10),
              Expanded(
                child: _DifficultyTile(
                  label: d.label,
                  ball: _ball(d),
                  selected: d == value,
                  onTap: () => onChanged(d),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFF1ECFC),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              const Text('💡', style: TextStyle(fontSize: 26)),
              const SizedBox(width: 12),
              Expanded(
                child: AnimatedSwitcher(
                  duration: AppDurations.fast,
                  layoutBuilder: (current, previous) => Stack(
                    alignment: Alignment.centerLeft,
                    children: [...previous, ?current],
                  ),
                  child: Text(
                    value.blurb,
                    key: ValueKey(value),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: PlayfulColors.muted,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DifficultyTile extends StatelessWidget {
  const _DifficultyTile({
    required this.label,
    required this.ball,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final Color ball;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: '$label difficulty',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: AppDurations.medium,
          curve: Curves.easeOutBack,
          height: 116,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: selected
                ? const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF8A5CF8), Color(0xFF6B3FE6)],
                  )
                : null,
            color: selected ? null : const Color(0xFFEEE8FB),
            border: Border.all(
              color: selected ? Colors.white : Colors.transparent,
              width: 3,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: PlayfulColors.accent.withValues(alpha: 0.4),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          transform: Matrix4.diagonal3Values(
            selected ? 1.0 : 0.95,
            selected ? 1.0 : 0.95,
            1,
          ),
          transformAlignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _GlossyBall(color: ball, size: selected ? 42 : 38),
              const SizedBox(height: 8),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: selected ? Colors.white : PlayfulColors.ink,
                  ),
                ),
              ),
              if (selected) ...[
                const SizedBox(height: 2),
                const Icon(
                  Icons.check_circle_rounded,
                  size: 20,
                  color: Colors.white,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Shiny 3D-looking sphere.
class _GlossyBall extends StatelessWidget {
  const _GlossyBall({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final hsl = HSLColor.fromColor(color);
    final light = hsl
        .withLightness((hsl.lightness + 0.2).clamp(0, 1))
        .toColor();
    final dark = hsl
        .withLightness((hsl.lightness - 0.18).clamp(0, 1))
        .toColor();
    return AnimatedContainer(
      duration: AppDurations.medium,
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: const Alignment(-0.35, -0.4),
          radius: 0.9,
          colors: [light, color, dark],
          stops: const [0, 0.5, 1],
        ),
        boxShadow: [
          BoxShadow(
            color: dark.withValues(alpha: 0.35),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Align(
        alignment: const Alignment(-0.3, -0.55),
        child: Container(
          width: size * 0.36,
          height: size * 0.2,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(size),
            color: Colors.white.withValues(alpha: 0.7),
          ),
        ),
      ),
    );
  }
}

class _ImposterStepper extends StatelessWidget {
  const _ImposterStepper({
    required this.value,
    required this.max,
    required this.onChanged,
  });

  final int value;
  final int max;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    Widget button(IconData icon, String label, int? next) {
      final enabled = next != null;
      return Semantics(
        button: true,
        enabled: enabled,
        label: label,
        excludeSemantics: true,
        child: Material(
          color: const Color(0xFFEAE5F7),
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: enabled ? () => onChanged(next) : null,
            child: SizedBox(
              width: 68,
              height: 68,
              child: Icon(
                icon,
                size: 32,
                color: enabled
                    ? PlayfulColors.muted
                    : PlayfulColors.soft.withValues(alpha: 0.5),
              ),
            ),
          ),
        ),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Sparks(color: PlayfulColors.yellow, mirrored: true),
        const SizedBox(width: 14),
        button(
          Icons.remove_rounded,
          'Fewer imposters',
          value > 1 ? value - 1 : null,
        ),
        SizedBox(
          width: 84,
          child: Semantics(
            label: '$value imposter${value == 1 ? '' : 's'}',
            excludeSemantics: true,
            child: AnimatedSwitcher(
              duration: AppDurations.fast,
              transitionBuilder: (child, a) =>
                  ScaleTransition(scale: a, child: child),
              child: Text(
                '$value',
                key: ValueKey(value),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 52,
                  fontWeight: FontWeight.w900,
                  height: 1,
                  color: PlayfulColors.accent,
                ),
              ),
            ),
          ),
        ),
        button(
          Icons.add_rounded,
          'More imposters',
          value < max ? value + 1 : null,
        ),
        const SizedBox(width: 14),
        const Sparks(color: Color(0xFF7B55EE)),
      ],
    );
  }
}

class _HintToggle extends StatelessWidget {
  const _HintToggle({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return FrostedCard(
      padding: EdgeInsets.zero,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () => onChanged(!value),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 16, 14),
            child: Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEE8FB),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Text('💡', style: TextStyle(fontSize: 30)),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Give a hint',
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          color: PlayfulColors.ink,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Help the imposter blend in.',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: PlayfulColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: value,
                  onChanged: onChanged,
                  activeThumbColor: Colors.white,
                  activeTrackColor: PlayfulColors.accent,
                  inactiveThumbColor: Colors.white,
                  inactiveTrackColor: PlayfulColors.field,
                  trackOutlineColor: const WidgetStatePropertyAll(
                    Colors.transparent,
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
