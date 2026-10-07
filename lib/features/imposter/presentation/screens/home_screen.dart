import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/router.dart';
import '../../../../app/theme/app_tokens.dart';
import '../../../../core/ads/banner_gate.dart';
import '../providers/providers.dart';
import '../widgets/home_background.dart';
import '../widgets/playful_ui.dart';
import 'how_to_play_screen.dart';
import 'player_setup_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final insets = MediaQuery.paddingOf(context);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: PlayfulColors.page,
        body: Stack(
          children: [
            const Positioned(
              left: 0,
              top: 0,
              width: 0,
              height: 0,
              child: SyncAnchoredBanner(allowed: true),
            ),
            LayoutBuilder(
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
                                constraints: const BoxConstraints(
                                  maxWidth: 480,
                                ),
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
          ],
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
        const SizedBox(height: AppSpacing.md),
        const Spacer(),
        const _Tagline(),
        const SizedBox(height: 44),
        PillButton(
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
        const SizedBox(height: 16),
        PillButton(
          label: 'HOW TO PLAY',
          icon: Icons.menu_book_outlined,
          onPressed: () => Navigator.of(
            context,
          ).push(GameRoute(builder: (_) => const HowToPlayScreen())),
        ),
        const SizedBox(height: 16),
        PillButton(
          label: 'SETTINGS',
          icon: Icons.settings_outlined,
          onPressed: () => Navigator.of(
            context,
          ).push(GameRoute(builder: (_) => const SettingsScreen())),
        ),
        const Spacer(),
        const SizedBox(height: AppSpacing.md),
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
                  color: PlayfulColors.muted,
                ),
              ),
              TextSpan(
                text: "One of you doesn't.",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.3,
                  color: PlayfulColors.accentDeep,
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
            gradient: LinearGradient(colors: PlayfulColors.primaryGradient),
          ),
        ),
      ],
    );
  }
}
