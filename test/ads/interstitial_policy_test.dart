import 'package:flutter_test/flutter_test.dart';
import 'package:undercover/core/ads/interstitial_policy.dart';

void main() {
  final now = DateTime(2026, 1, 1, 12);

  bool show({
    bool fromNextRound = true,
    bool skipNext = false,
    int roundsPlayed = 4,
    DateTime? lastShownAt,
  }) {
    return InterstitialPolicy.shouldShow(
      fromNextRound: fromNextRound,
      skipNext: skipNext,
      roundsPlayed: roundsPlayed,
      lastShownAt: lastShownAt,
      now: now,
    );
  }

  test('shows on every 4th next-round tap after a quiet period', () {
    expect(show(roundsPlayed: 4), isTrue);
    expect(show(roundsPlayed: 8), isTrue);
    expect(show(roundsPlayed: 3), isFalse);
    expect(show(roundsPlayed: 0), isFalse);
    expect(show(fromNextRound: false), isFalse);
    expect(show(skipNext: true), isFalse);
  });

  test('skips when the previous interstitial was too recent', () {
    expect(
      show(lastShownAt: now.subtract(const Duration(seconds: 30))),
      isFalse,
    );
    expect(
      show(lastShownAt: now.subtract(InterstitialPolicy.minimumInterval)),
      isTrue,
    );
  });
}
