import 'package:flutter_test/flutter_test.dart';
import 'package:undercover/features/imposter/domain/services/game_rules.dart';
import 'package:undercover/features/imposter/domain/services/player_validator.dart';

import '../helpers/test_helpers.dart';

void main() {
  final existing = makePlayers(3); // Player 1..3

  PlayerNameError? v(
    String name, {
    bool dup = false,
    String? renaming,
    int? count,
  }) => PlayerValidator.validate(
    name,
    existing: count == null ? existing : makePlayers(count),
    allowDuplicates: dup,
    renamingId: renaming,
  );

  test('trims and collapses whitespace', () {
    expect(PlayerValidator.normalize('  Rahul   Sharma '), 'Rahul Sharma');
  });

  test('rejects empty and whitespace-only names', () {
    expect(v(''), PlayerNameError.empty);
    expect(v('    '), PlayerNameError.empty);
  });

  test('rejects names over the character limit', () {
    expect(v('A' * (GameRules.maxNameLength + 1)), PlayerNameError.tooLong);
    expect(v('A' * GameRules.maxNameLength), isNull);
  });

  test('rejects duplicates case-insensitively after trimming', () {
    expect(v('player 1'), PlayerNameError.duplicate);
    expect(v('  PLAYER 2 '), PlayerNameError.duplicate);
  });

  test('allows duplicates when enabled', () {
    expect(v('Player 1', dup: true), isNull);
  });

  test('renaming a player to their own name is fine', () {
    expect(v('Player 1', renaming: 'p1'), isNull);
    expect(v('Player 2', renaming: 'p1'), PlayerNameError.duplicate);
  });

  test('rejects adding past the maximum player count', () {
    expect(
      v('New', count: GameRules.maxPlayers),
      PlayerNameError.tooManyPlayers,
    );
    expect(v('New', count: GameRules.maxPlayers - 1), isNull);
  });
}
