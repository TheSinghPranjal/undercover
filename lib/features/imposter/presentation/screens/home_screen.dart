import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/router.dart';
import '../../../../app/theme/app_tokens.dart';
import '../providers/providers.dart';
import '../widgets/home_background.dart';
import 'how_to_play_screen.dart';
import 'player_setup_screen.dart';
import 'settings_screen.dart';

/// Fixed palette for the illustrated home screen – the artwork is light, so
/// this screen stays light regardless of the app theme.
abstract final class _HomeColors {
  static const ink = Color(0xFF2B2656);
  static const muted = Color(0xFF5E5A78);
  static const accent = Color(0xFF6B46E5);
  static const accentDeep = Color(0xFF4B2BB8);
  static const outline = Color(0xFFCBC2E6);
  static const startGradient = [Color(0xFF7447EE), Color(0xFF9063FA)];
}

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final insets = MediaQuery.paddingOf(context);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: const Color(0xFFF4EFFD),
        body: LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            final h = constraints.maxHeight;
            const src = HomeBackground.imageSize;
            const headerRows =
                HomeBackground.headerEndRow - HomeBackground.headerStartRow;
            // Slight zoom so the characters fill the width like the mock,
            // but never so tall the header eats more than half the screen.
            final scale = max(
              w / src.width,
              min(w * 1.06 / src.width, h * 0.5 / headerRows),
            );
            final headerTop = insets.top;
            final headerBottom = headerTop + headerRows * scale;

            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: h),
                child: IntrinsicHeight(
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: HomeBackground(
                          headerTop: headerTop,
                          scale: scale,
                        ),
                      ),
                      Positioned(
                        top: headerTop,
                        left: 0,
                        right: 0,
                        height: headerBottom - headerTop,
                        child: Semantics(
                          header: true,
                          label: 'Find the Imposter',
                          child: const SizedBox.expand(),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          28,
                          headerBottom - 4,
                          28,
                          insets.bottom + AppSpacing.md,
                        ),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 480),
                            child: _HomeContent(ref: ref),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _HomeContent extends StatelessWidget {
  const _HomeContent({required this.ref});

  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const _Tagline(),
        const SizedBox(height: 36),
        _PillButton(
          label: 'START GAME',
          icon: Icons.play_arrow_rounded,
          primary: true,
          onPressed: () {
            ref.read(gameControllerProvider.notifier).goToPlayerSetup();
            Navigator.of(
              context,
            ).push(GameRoute(builder: (_) => const PlayerSetupScreen()));
          },
        ),
        const SizedBox(height: 12),
        _PillButton(
          label: 'HOW TO PLAY',
          icon: Icons.menu_book_outlined,
          onPressed: () => Navigator.of(
            context,
          ).push(GameRoute(builder: (_) => const HowToPlayScreen())),
        ),
        const SizedBox(height: 12),
        _PillButton(
          label: 'SETTINGS',
          icon: Icons.settings_outlined,
          onPressed: () => Navigator.of(
            context,
          ).push(GameRoute(builder: (_) => const SettingsScreen())),
        ),
      ],
    );
  }
}

/// "Everyone knows the word. One of you doesn't." styled to match the logo:
/// a soft lead-in, then a bold purple punchline with a highlighter swipe.
class _Tagline extends StatelessWidget {
  const _Tagline();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text.rich(
          const TextSpan(
            children: [
              TextSpan(
                text: 'Everyone knows the word.\n',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                  color: _HomeColors.muted,
                ),
              ),
              TextSpan(
                text: "One of you doesn't.",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.3,
                  color: _HomeColors.accentDeep,
                  shadows: [
                    Shadow(color: Colors.white, offset: Offset(0, 2)),
                    Shadow(
                      color: Color(0x406B46E5),
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
              ),
            ],
          ),
          textAlign: TextAlign.center,
          style: const TextStyle(height: 1.35),
        ),
        const SizedBox(height: 8),
        Container(
          width: 64,
          height: 5,
          decoration: const BoxDecoration(
            borderRadius: AppRadius.pill,
            gradient: LinearGradient(colors: _HomeColors.startGradient),
          ),
        ),
      ],
    );
  }
}

/// Pill-shaped home action: filled gradient for the primary action,
/// soft outline for the rest.
class _PillButton extends ConsumerStatefulWidget {
  const _PillButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.primary = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final bool primary;

  @override
  ConsumerState<_PillButton> createState() => _PillButtonState();
}

class _PillButtonState extends ConsumerState<_PillButton> {
  bool _pressed = false;

  void _setPressed(bool v) {
    if (_pressed != v) setState(() => _pressed = v);
  }

  void _handleTap() {
    ref.read(soundProvider).tap();
    ref.read(hapticsProvider).selection();
    widget.onPressed();
  }

  @override
  Widget build(BuildContext context) {
    final primary = widget.primary;
    final foreground = primary ? Colors.white : _HomeColors.ink;
    return Listener(
      onPointerDown: (_) => _setPressed(true),
      onPointerUp: (_) => _setPressed(false),
      onPointerCancel: (_) => _setPressed(false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1,
        duration: AppDurations.fast,
        curve: Curves.easeOut,
        child: DecoratedBox(
          decoration: ShapeDecoration(
            shape: StadiumBorder(
              side: primary
                  ? BorderSide.none
                  : const BorderSide(color: _HomeColors.outline, width: 1.5),
            ),
            color: primary ? null : Colors.white.withValues(alpha: 0.35),
            gradient: primary
                ? const LinearGradient(colors: _HomeColors.startGradient)
                : null,
            shadows: primary
                ? [
                    BoxShadow(
                      color: _HomeColors.accent.withValues(alpha: 0.35),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : null,
          ),
          child: Material(
            type: MaterialType.transparency,
            shape: const StadiumBorder(),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: _handleTap,
              child: SizedBox(
                height: primary ? 58 : 50,
                width: double.infinity,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      widget.icon,
                      size: primary ? 34 : 26,
                      color: primary ? Colors.white : _HomeColors.accent,
                    ),
                    SizedBox(width: primary ? 18 : 14),
                    Text(
                      widget.label,
                      style: TextStyle(
                        fontSize: primary ? 20 : 17,
                        fontWeight: FontWeight.w700,
                        letterSpacing: primary ? 1 : 0.8,
                        color: foreground,
                      ),
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
