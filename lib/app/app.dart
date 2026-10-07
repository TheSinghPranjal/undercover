import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/ads/banner_ad_slot.dart';
import '../core/ads/banner_gate.dart';
import '../core/widgets/uniform_scale.dart';
import '../features/imposter/domain/enums/game_phase.dart';
import '../features/imposter/presentation/providers/providers.dart';
import '../features/imposter/presentation/screens/splash_screen.dart';
import 'theme/app_theme.dart';

class FindTheImposterApp extends ConsumerWidget {
  const FindTheImposterApp({super.key, this.home = const SplashScreen()});

  final Widget home;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final phase = ref.watch(gamePhaseProvider);
    final showBanner = showAnchoredBanner(
      holds: ref.watch(anchoredBannerHoldsProvider),
      suppressed: ref.watch(anchoredBannerSuppressProvider),
      // Secrets, the pass-the-phone hand-off, and the deal that starts it.
      blocked: phase.isRevealFlow || phase == GamePhase.generatingRound,
    );
    return MaterialApp(
      title: 'Undercover',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ref.watch(themeModeProvider),
      // Every screen, dialog and sheet is drawn 20% smaller. The banner stays
      // outside that scale: a platform ad view does not follow the transform.
      builder: (context, child) {
        final scaled = UniformScale(
          scale: 0.8,
          child: child ?? const SizedBox.shrink(),
        );
        if (!showBanner) return scaled;
        return Column(
          children: [
            Expanded(child: scaled),
            const BannerAdSlot(),
          ],
        );
      },
      home: home,
    );
  }
}
