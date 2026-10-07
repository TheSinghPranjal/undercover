import 'package:flutter_test/flutter_test.dart';
import 'package:undercover/core/ads/ads_service.dart';
import 'package:undercover/core/ads/banner_gate.dart';
import 'package:undercover/core/ads/interstitial_policy.dart';
import 'package:undercover/features/imposter/domain/enums/game_phase.dart';
import 'package:undercover/features/imposter/presentation/providers/providers.dart';

import '../helpers/test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('banner stays off for the whole secret hand-off', () {
    for (final phase in GamePhase.values) {
      final secret = phase.isRevealFlow || phase == GamePhase.generatingRound;
      expect(
        showAnchoredBanner(holds: 1, suppressed: false, blocked: secret),
        isNot(secret),
        reason: phase.name,
      );
    }
    expect(
      showAnchoredBanner(holds: 1, suppressed: true, blocked: false),
      isFalse,
    );
    expect(
      showAnchoredBanner(holds: 0, suppressed: false, blocked: false),
      isFalse,
    );
  });

  test(
    'interstitial fires on the 4th next round, then waits 90 seconds',
    () async {
      final ads = FakeAdsService();
      final c = await makeContainer(
        extra: [adsServiceProvider.overrideWithValue(ads)],
      );
      final game = c.read(gameControllerProvider.notifier);
      for (var i = 1; i <= 3; i++) {
        expect(game.addPlayer('Player $i'), isNull);
      }

      ads.onInterstitial = () {
        final phase = c.read(gamePhaseProvider);
        expect(phase, GamePhase.roundReady);
        expect(phase.isRevealFlow, isFalse);
      };

      Future<void> finishReveal() async {
        final before = ads.interstitialShows;
        final total = c.read(gameControllerProvider).round!.players.length;
        for (var i = 0; i < total; i++) {
          game.confirmReady();
          game.beginHold();
          game.revealCurrentPlayer();
          if (i < total - 1) {
            game.passToNextPlayer();
          } else {
            game.finishRevealPhase();
          }
          game.completePass();
        }
        expect(c.read(gamePhaseProvider), GamePhase.roundReady);
        expect(ads.interstitialShows, before);
      }

      await game.startRound();
      expect(ads.interstitialShows, 0);
      await finishReveal();

      for (var n = 1; n <= 3; n++) {
        await game.startNextRound();
        expect(ads.interstitialShows, 0);
        expect(c.read(gamePhaseProvider), GamePhase.passPhone);
        await finishReveal();
      }

      await game.startNextRound();
      expect(ads.interstitialShows, 1);
      expect(c.read(gamePhaseProvider), GamePhase.passPhone);
      await finishReveal();

      for (var n = 5; n <= 7; n++) {
        await game.startNextRound();
        expect(ads.interstitialShows, 1);
        await finishReveal();
      }

      await game.startNextRound();
      expect(
        ads.interstitialShows,
        1,
        reason: 'round 8 is due, but the previous ad was under 90 seconds ago',
      );
      expect(InterstitialPolicy.everyNRounds, 4);
      expect(InterstitialPolicy.minimumInterval, const Duration(seconds: 90));
    },
  );
}
