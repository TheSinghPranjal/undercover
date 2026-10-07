import 'package:flutter_test/flutter_test.dart';
import 'package:undercover/core/ads/ads_service.dart';
import 'package:undercover/core/ads/banner_ad_slot.dart';
import 'package:undercover/features/imposter/domain/enums/game_phase.dart';
import 'package:undercover/features/imposter/presentation/providers/providers.dart';
import 'package:undercover/features/imposter/presentation/screens/game_config_screen.dart';
import 'package:undercover/features/imposter/presentation/screens/home_screen.dart';

import '../helpers/test_helpers.dart';

void main() {
  testWidgets('menu shows a banner; player setup does not', (tester) async {
    await pumpApp(tester, const HomeScreen());
    expect(find.byType(BannerAdSlot), findsOneWidget);

    await tester.tap(find.text('START GAME'));
    await tester.pumpAndSettle();
    expect(find.byType(BannerAdSlot), findsNothing);
  });

  testWidgets('no banner during the reveal; it returns only when ready', (
    tester,
  ) async {
    final ads = FakeAdsService();
    final c = await pumpApp(
      tester,
      const GameConfigScreen(),
      prefs: {
        'roster.names': ['Rahul', 'Priya', 'Aman'],
      },
      extra: [adsServiceProvider.overrideWithValue(ads)],
    );
    await tester.tap(find.text('PASS THE PHONE'));
    await tester.pumpAndSettle();

    expect(find.text('GIVE THE PHONE TO'), findsOneWidget);
    expect(find.byType(BannerAdSlot), findsNothing);
    expect(c.read(gamePhaseProvider).isRevealFlow, isTrue);
    expect(ads.interstitialShows, 0);

    final game = c.read(gameControllerProvider.notifier);
    for (var i = 0; i < 3; i++) {
      game.confirmReady();
      game.beginHold();
      game.revealCurrentPlayer();
      if (i < 2) {
        game.passToNextPlayer();
      } else {
        game.finishRevealPhase();
      }
      game.completePass();
      expect(ads.interstitialShows, 0);
    }
    await tester.pumpAndSettle();

    expect(c.read(gamePhaseProvider), GamePhase.roundReady);
    expect(find.byType(BannerAdSlot), findsOneWidget);
    expect(find.text('YOUR SECRET WORD'), findsNothing);
    expect(find.text('THE IMPOSTER'), findsNothing);

    await tester.tap(find.text('AGAIN! 🔥'));
    await tester.pumpAndSettle();
    expect(find.text('GIVE THE PHONE TO'), findsOneWidget);
    expect(find.byType(BannerAdSlot), findsNothing);
    expect(c.read(gamePhaseProvider).isRevealFlow, isTrue);
    expect(ads.interstitialShows, 0);
  });
}
