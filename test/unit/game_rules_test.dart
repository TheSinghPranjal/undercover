import 'package:flutter_test/flutter_test.dart';
import 'package:undercover/features/imposter/domain/services/game_rules.dart';

void main() {
  group('GameRules.maxImposters', () {
    const table = {
      3: 1,
      4: 1,
      5: 1,
      6: 2,
      7: 2,
      8: 2,
      9: 3,
      10: 3,
      12: 4,
      15: 5,
      18: 6,
      20: 6,
    };
    table.forEach((players, expected) {
      test('$players players → $expected', () {
        expect(GameRules.maxImposters(players), expected);
      });
    });

    test('never exceeds seats from position 3 onwards', () {
      for (var n = GameRules.minPlayers; n <= GameRules.maxPlayers; n++) {
        expect(
          GameRules.maxImposters(n),
          lessThanOrEqualTo(n - GameRules.protectedPositions),
        );
        expect(GameRules.maxImposters(n), greaterThanOrEqualTo(1));
      }
    });
  });

  test('clampImposters keeps the value within 1..max', () {
    expect(GameRules.clampImposters(5, 8), 2);
    expect(GameRules.clampImposters(0, 8), 1);
    expect(GameRules.clampImposters(2, 8), 2);
    expect(GameRules.clampImposters(3, 5), 1);
  });

  test('player limits', () {
    expect(GameRules.minPlayers, 3);
    expect(GameRules.maxPlayers, 20);
  });
}
