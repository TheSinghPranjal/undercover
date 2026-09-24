import 'dart:math';

/// Single home for every numeric rule in the game.
abstract final class GameRules {
  static const int minPlayers = 3;
  static const int maxPlayers = 20;
  static const int recommendedMinPlayers = 4;
  static const int recommendedMaxPlayers = 10;
  static const int maxNameLength = 16;

  /// Players in seats 1..[protectedPositions] are never dealt the imposter.
  static const int protectedPositions = 2;

  static const int defaultImposterCount = 1;
  static const int recentWordLimit = 20;

  static const Duration revealHoldDuration = Duration(milliseconds: 850);

  /// floor(players / 3), never more than the number of eligible seats, and
  /// never less than 1.
  static int maxImposters(int playerCount) {
    if (playerCount < minPlayers) return 1;
    final eligibleSeats = playerCount - protectedPositions;
    return max(1, min(playerCount ~/ 3, eligibleSeats));
  }

  static int clampImposters(int requested, int playerCount) =>
      requested.clamp(1, maxImposters(playerCount));
}
