import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:undercover/features/imposter/domain/enums/difficulty.dart';
import 'package:undercover/features/imposter/domain/enums/game_phase.dart';
import 'package:undercover/features/imposter/domain/services/game_rules.dart';
import 'package:undercover/features/imposter/domain/services/player_validator.dart';
import 'package:undercover/features/imposter/presentation/controllers/game_controller.dart';
import 'package:undercover/features/imposter/presentation/providers/providers.dart';

import '../helpers/test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ProviderContainer c;
  GameController game() => c.read(gameControllerProvider.notifier);
  GamePhase phase() => c.read(gameControllerProvider).phase;

  Future<void> addPlayers(int n) async {
    for (var i = 1; i <= n; i++) {
      expect(game().addPlayer('Player $i'), isNull);
    }
  }

  /// Reveal and pass for the current player.
  void revealAndPass() {
    game().confirmReady();
    game().beginHold();
    game().revealCurrentPlayer();
    game().passToNextPlayer();
    game().completePass();
  }

  setUp(() async => c = await makeContainer());

  group('players', () {
    test('adds, renames, removes and renumbers', () async {
      await addPlayers(4);
      game().removePlayer(c.read(playersProvider)[1].id);
      final players = c.read(playersProvider);
      expect(players.map((p) => p.position), [1, 2, 3]);
      expect(players.map((p) => p.name), ['Player 1', 'Player 3', 'Player 4']);
      expect(game().renamePlayer(players[0].id, 'Rahul'), isNull);
      expect(c.read(playersProvider).first.name, 'Rahul');
    });

    test('rejects duplicates unless allowed, with unique ids', () async {
      await addPlayers(1);
      expect(game().addPlayer('player 1'), PlayerNameError.duplicate);
      c.read(gameSettingsProvider.notifier).setAllowDuplicateNames(true);
      expect(game().addPlayer('Player 1'), isNull);
      final ids = c.read(playersProvider).map((p) => p.id).toSet();
      expect(ids, hasLength(2));
    });

    test('caps at the maximum', () async {
      await addPlayers(GameRules.maxPlayers);
      expect(game().addPlayer('One more'), PlayerNameError.tooManyPlayers);
    });

    test('cannot configure below the minimum', () async {
      await addPlayers(2);
      game().goToConfiguration();
      expect(phase(), GamePhase.playerSetup);
      await game().startRound();
      expect(c.read(gameControllerProvider).round, isNull);
    });

    test('roster is remembered across launches', () async {
      await addPlayers(3);
      final sp = c.read(sharedPreferencesProvider);
      final c2 = await makeContainer(
        prefs: {'roster.names': sp.getStringList('roster.names')!},
      );
      expect(c2.read(playersProvider).map((p) => p.name), [
        'Player 1',
        'Player 2',
        'Player 3',
      ]);
    });
  });

  group('round flow', () {
    test(
      'full reveal loop ends on the final-player state then round ready',
      () async {
        await addPlayers(5);
        game().goToConfiguration();
        await game().startRound();
        expect(phase(), GamePhase.passPhone);

        for (var i = 0; i < 4; i++) {
          expect(c.read(currentPlayerProvider)!.position, i + 1);
          game().confirmReady();
          expect(phase(), GamePhase.readyToReveal);
          expect(
            c.read(currentAssignmentProvider),
            isNull,
            reason: 'secret hidden while face-down',
          );
          game().beginHold();
          game().revealCurrentPlayer();
          expect(phase(), GamePhase.revealed);
          expect(c.read(currentAssignmentProvider), isNotNull);
          game().passToNextPlayer();
          expect(phase(), GamePhase.passing);
          game().completePass();
          expect(phase(), GamePhase.passPhone);
          expect(c.read(currentAssignmentProvider), isNull);
        }

        game().confirmReady();
        game().beginHold();
        game().revealCurrentPlayer();
        expect(
          phase(),
          GamePhase.allPlayersRevealed,
          reason: 'last player sees START GAME, not PASS',
        );
        expect(
          c.read(startingPlayerProvider),
          isNull,
          reason: 'starting player hidden until every card is seen',
        );

        game().finishRevealPhase();
        game().completePass();
        expect(phase(), GamePhase.roundReady);
        expect(c.read(startingPlayerProvider), isNotNull);
        expect(c.read(currentAssignmentProvider), isNull);
      },
    );

    test('cancelling a hold returns to the face-down card', () async {
      await addPlayers(3);
      await game().startRound();
      game().confirmReady();
      game().beginHold();
      game().cancelHold();
      expect(phase(), GamePhase.readyToReveal);
    });

    test(
      'next round keeps players and settings but deals a new word',
      () async {
        await addPlayers(6);
        c.read(gameSettingsProvider.notifier)
          ..setDifficulty(Difficulty.difficult)
          ..setImposterCount(2)
          ..setShowHint(true);
        final seen = <String>[];
        for (var round = 0; round < 25; round++) {
          await (round == 0 ? game().startRound() : game().startNextRound());
          final r = c.read(gameControllerProvider).round!;
          expect(r.difficulty, Difficulty.difficult);
          expect(r.imposterIds, hasLength(2));
          expect(
            r.imposterIds,
            isNot(anyOf(contains(r.players[0].id), contains(r.players[1].id))),
          );
          for (final id in r.imposterIds) {
            expect(r.assignmentFor(id).hint, isNotNull);
            expect(r.assignmentFor(id).word, isNull);
          }
          expect(seen, isNot(contains(r.word.id)));
          seen.add(r.word.id);
          if (seen.length > GameRules.recentWordLimit) seen.removeAt(0);
          expect(r.players, hasLength(6));
          for (var i = 0; i < 6; i++) {
            if (i < 5) {
              revealAndPass();
            } else {
              game().confirmReady();
              game().revealCurrentPlayer();
              game().finishRevealPhase();
              game().completePass();
            }
          }
          expect(phase(), GamePhase.roundReady);
        }
      },
    );

    test('imposter count is clamped to the group size', () async {
      await addPlayers(5);
      c.read(gameSettingsProvider.notifier).setImposterCount(3);
      expect(c.read(effectiveImposterCountProvider), 1);
      await game().startRound();
      expect(c.read(gameControllerProvider).round!.imposterIds, hasLength(1));
    });

    test('exit discards the round', () async {
      await addPlayers(3);
      await game().startRound();
      game().exitRound();
      expect(phase(), GamePhase.configuration);
      expect(c.read(gameControllerProvider).round, isNull);
    });
  });

  group('lifecycle privacy', () {
    setUp(() async {
      await addPlayers(4);
      await game().startRound();
      game().confirmReady();
      game().beginHold();
      game().revealCurrentPlayer();
    });

    test(
      'hiding a revealed card requires the player to confirm and hold again',
      () {
        final before = c.read(currentPlayerProvider);
        game().hideCurrentPlayer();
        expect(phase(), GamePhase.privacyHidden);
        expect(c.read(currentAssignmentProvider), isNull);
        expect(c.read(currentPlayerProvider), before);
        game().confirmReady();
        expect(phase(), GamePhase.readyToReveal);
        expect(c.read(currentAssignmentProvider), isNull);
      },
    );

    test('hiding mid-hold cancels the hold', () {
      game().hideCurrentPlayer(); // → privacyHidden
      game().confirmReady();
      game().beginHold();
      game().hideCurrentPlayer();
      expect(phase(), GamePhase.readyToReveal);
    });

    test('hiding while passing moves straight on to the next player', () {
      game().passToNextPlayer();
      game().hideCurrentPlayer();
      expect(phase(), GamePhase.passPhone);
      expect(c.read(currentPlayerProvider)!.position, 2);
    });

    test('hiding the last card', () {
      for (var i = 0; i < 3; i++) {
        if (phase() == GamePhase.revealed) {
          game().passToNextPlayer();
          game().completePass();
        }
        game().confirmReady();
        game().revealCurrentPlayer();
      }
      expect(phase(), GamePhase.allPlayersRevealed);
      game().hideCurrentPlayer();
      expect(phase(), GamePhase.privacyHidden);
      game().confirmReady();
      game().revealCurrentPlayer();
      expect(phase(), GamePhase.allPlayersRevealed);
    });
  });

  group('settings', () {
    test('persist across launches and reset to defaults', () async {
      c.read(gameSettingsProvider.notifier)
        ..setDifficulty(Difficulty.medium)
        ..setShowHint(true)
        ..setHaptics(false);
      await Future<void>.delayed(Duration.zero);
      final sp = c.read(sharedPreferencesProvider);
      final stored = {for (final k in sp.getKeys()) k: sp.get(k)!};
      final c2 = await makeContainer(prefs: stored);
      final s = c2.read(gameSettingsProvider);
      expect(s.difficulty, Difficulty.medium);
      expect(s.showHint, isTrue);
      expect(s.hapticsEnabled, isFalse);

      await c2.read(gameSettingsProvider.notifier).reset();
      expect(c2.read(gameSettingsProvider).difficulty, Difficulty.easy);
      expect(c2.read(gameSettingsProvider).imposterCount, 1);
      expect(c2.read(gameSettingsProvider).showHint, isFalse);
    });

    test('defaults are Easy / 1 imposter / hint off', () {
      final s = c.read(gameSettingsProvider);
      expect(s.difficulty, Difficulty.easy);
      expect(s.imposterCount, 1);
      expect(s.showHint, isFalse);
    });
  });
}
