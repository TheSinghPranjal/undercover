import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:undercover/features/imposter/domain/entities/word_entry.dart';
import 'package:undercover/features/imposter/domain/enums/difficulty.dart';
import 'package:undercover/features/imposter/domain/enums/role.dart';
import 'package:undercover/features/imposter/domain/services/game_rules.dart';
import 'package:undercover/features/imposter/domain/services/round_generator.dart';

import '../helpers/test_helpers.dart';

const water = WordEntry(
  id: 'easy_x',
  difficulty: Difficulty.easy,
  category: 'nature',
  word: 'Water',
  hint: 'Liquid',
);

void main() {
  final generator = RoundGenerator(random: Random(1));

  group('imposter selection', () {
    for (final (players, imposters) in [
      (3, 1),
      (5, 1),
      (6, 2),
      (8, 2),
      (9, 3),
      (10, 3),
      (20, 6),
    ]) {
      test(
        '$players players / $imposters imposters: never seat 1 or 2, unique, exact count',
        () {
          final ps = makePlayers(players);
          for (var i = 0; i < 2000; i++) {
            final round = generator.generate(
              players: ps,
              word: water,
              imposterCount: imposters,
              showHint: false,
            );
            expect(round.imposterIds, hasLength(imposters));
            expect(round.imposterIds, isNot(contains('p1')));
            expect(round.imposterIds, isNot(contains('p2')));
            final roles = round.assignments.values
                .where((a) => a.role == Role.imposter)
                .map((a) => a.playerId)
                .toSet();
            expect(roles, round.imposterIds);
          }
        },
      );
    }

    test('every eligible seat gets picked, roughly uniformly', () {
      final ps = makePlayers(7);
      final counts = <String, int>{};
      const rounds = 20000;
      for (var i = 0; i < rounds; i++) {
        final r = generator.generate(
          players: ps,
          word: water,
          imposterCount: 1,
          showHint: false,
        );
        counts.update(r.imposterIds.single, (c) => c + 1, ifAbsent: () => 1);
      }
      expect(counts.keys.toSet(), {'p3', 'p4', 'p5', 'p6', 'p7'});
      for (final c in counts.values) {
        expect(c / rounds, closeTo(1 / 5, 0.02));
      }
    });

    test('uses seat position, not list order', () {
      final ps = makePlayers(5).reversed.toList();
      for (var i = 0; i < 500; i++) {
        final r = generator.generate(
          players: ps,
          word: water,
          imposterCount: 1,
          showHint: false,
        );
        expect(r.imposterIds, isNot(anyOf(contains('p1'), contains('p2'))));
      }
    });

    test('clamps an impossible imposter count', () {
      final r = generator.generate(
        players: makePlayers(5),
        word: water,
        imposterCount: 4,
        showHint: false,
      );
      expect(r.imposterIds, hasLength(GameRules.maxImposters(5)));
    });

    test('rejects fewer than the minimum players', () {
      expect(
        () => generator.generate(
          players: makePlayers(2),
          word: water,
          imposterCount: 1,
          showHint: false,
        ),
        throwsArgumentError,
      );
    });
  });

  group('assignments', () {
    test('civilians get the word; imposters never do', () {
      final r = generator.generate(
        players: makePlayers(9),
        word: water,
        imposterCount: 3,
        showHint: true,
      );
      for (final a in r.assignments.values) {
        if (a.isImposter) {
          expect(a.word, isNull);
          expect(a.hint, 'Liquid');
        } else {
          expect(a.word, 'Water');
          expect(a.hint, isNull);
        }
      }
    });

    test('no hint when hints are off', () {
      final r = generator.generate(
        players: makePlayers(6),
        word: water,
        imposterCount: 2,
        showHint: false,
      );
      for (final a in r.assignments.values.where((a) => a.isImposter)) {
        expect(a.hint, isNull);
        expect(a.word, isNull);
      }
    });
  });

  group('starting player', () {
    test('any player can start, including seats 1 and 2', () {
      final ps = makePlayers(5);
      final starters = <String>{};
      for (var i = 0; i < 500; i++) {
        starters.add(
          generator
              .generate(
                players: ps,
                word: water,
                imposterCount: 1,
                showHint: false,
              )
              .startingPlayerId,
        );
      }
      expect(starters, {'p1', 'p2', 'p3', 'p4', 'p5'});
    });

    test(
      'is independent of the imposter (imposter starts ~1/n of the time)',
      () {
        final ps = makePlayers(6);
        var imposterStarts = 0;
        const rounds = 20000;
        for (var i = 0; i < rounds; i++) {
          final r = generator.generate(
            players: ps,
            word: water,
            imposterCount: 1,
            showHint: false,
          );
          if (r.imposterIds.contains(r.startingPlayerId)) imposterStarts++;
        }
        expect(imposterStarts / rounds, closeTo(1 / 6, 0.02));
      },
    );
  });

  test('toString never leaks the secret', () {
    final r = generator.generate(
      players: makePlayers(4),
      word: water,
      imposterCount: 1,
      showHint: true,
    );
    final dump = [
      r.toString(),
      r.word.toString(),
      for (final a in r.assignments.values) a.toString(),
    ].join();
    expect(dump.toLowerCase(), isNot(contains('water')));
    expect(dump.toLowerCase(), isNot(contains('liquid')));
    for (final id in r.imposterIds) {
      expect(dump, isNot(contains(id)));
    }
  });
}
