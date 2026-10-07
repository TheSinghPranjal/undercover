/// When an "again" tap may show an interstitial between rounds.
///
/// Requires both a round cadence and a minimum quiet period so fast rounds
/// cannot stack full-screen ads. The pass-the-phone reveal never calls this.
class InterstitialPolicy {
  InterstitialPolicy._();

  /// Show on every Nth completed round, when the player asks for another.
  static const int everyNRounds = 4;

  /// Extra quiet period so several fast rounds cannot stack interstitials.
  static const Duration minimumInterval = Duration(seconds: 90);

  static bool shouldShow({
    required bool fromNextRound,
    required bool skipNext,
    required int roundsPlayed,
    required DateTime? lastShownAt,
    required DateTime now,
  }) {
    if (!fromNextRound || skipNext) return false;
    if (roundsPlayed <= 0 || roundsPlayed % everyNRounds != 0) {
      return false;
    }
    final last = lastShownAt;
    if (last != null && now.difference(last) < minimumInterval) {
      return false;
    }
    return true;
  }
}
