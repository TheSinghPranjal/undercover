import 'package:flutter_test/flutter_test.dart';
import 'package:undercover/features/imposter/data/datasources/word_asset_datasource.dart';
import 'package:undercover/features/imposter/domain/entities/word_entry.dart';
import 'package:undercover/features/imposter/domain/enums/difficulty.dart';
import 'package:undercover/features/imposter/domain/services/word_pack_validator.dart';

import '../helpers/test_helpers.dart';

void main() {
  group('bundled word pack', () {
    final pack = realWordPack();

    test('passes validation', () {
      expect(WordPackValidator.validate(pack), isEmpty);
    });

    test('has exactly 200 words per difficulty', () {
      expect(pack, hasLength(600));
      for (final d in Difficulty.values) {
        expect(
          pack.where((e) => e.difficulty == d),
          hasLength(200),
          reason: d.key,
        );
      }
    });

    test('is not dominated by one category', () {
      final counts = <String, int>{};
      for (final e in pack) {
        counts.update(e.category, (c) => c + 1, ifAbsent: () => 1);
      }
      expect(counts.length, inInclusiveRange(15, 25));
      for (final c in counts.values) {
        expect(c / pack.length, lessThan(0.1));
      }
    });
  });

  group('hint leak detection', () {
    test('flags hints that give away the word', () {
      expect(WordPackValidator.hintGivesAwayWord('Water', 'Water'), isTrue);
      expect(
        WordPackValidator.hintGivesAwayWord('Water', 'water bottle'),
        isTrue,
      );
      expect(WordPackValidator.hintGivesAwayWord('Sunflower', 'Sun'), isTrue);
      expect(
        WordPackValidator.hintGivesAwayWord('Ice Cream', 'Creamy ice'),
        isTrue,
      );
      expect(WordPackValidator.hintGivesAwayWord('Cards', 'Card game'), isTrue);
    });

    test('accepts genuine hints', () {
      expect(WordPackValidator.hintGivesAwayWord('Water', 'Liquid'), isFalse);
      expect(WordPackValidator.hintGivesAwayWord('Apple', 'Orchard'), isFalse);
    });
  });

  group('validator rejects broken packs', () {
    WordEntry e(
      String id,
      String word,
      String hint, {
      Difficulty d = Difficulty.easy,
      String category = 'food',
    }) => WordEntry(
      id: id,
      difficulty: d,
      category: category,
      word: word,
      hint: hint,
    );

    List<String> check(List<WordEntry> entries) =>
        WordPackValidator.validate(entries, perDifficulty: 1);

    final valid = [
      e('a', 'Pizza', 'Cheesy'),
      e('b', 'Volcano', 'Eruption', d: Difficulty.medium),
      e('c', 'Origami', 'Folding', d: Difficulty.difficult),
    ];

    test('valid mini pack', () => expect(check(valid), isEmpty));

    test('wrong counts', () {
      expect(check(valid.sublist(0, 2)), isNotEmpty);
    });

    test('duplicate ids and words', () {
      expect(
        check([
          ...valid.sublist(0, 2),
          e('a', 'pizza', 'Slice', d: Difficulty.difficult),
        ]),
        containsAll([contains('Duplicate id'), contains('duplicate of')]),
      );
    });

    test('empty hint, unknown category, leaking hint', () {
      final errors = check([
        e('a', 'Pizza', ''),
        e('b', 'Volcano', 'Volcano eruption', d: Difficulty.medium),
        e(
          'c',
          'Origami',
          'Folding',
          d: Difficulty.difficult,
          category: 'politics',
        ),
      ]);
      expect(errors, contains(contains('empty hint')));
      expect(errors, contains(contains('gives away')));
      expect(errors, contains(contains('unknown category')));
    });

    test('parser rejects an invalid difficulty', () {
      expect(
        () => WordAssetDataSource.parse(
          '{"words":[{"id":"x","difficulty":"extreme","category":"food","word":"A","hint":"B"}]}',
        ),
        throwsFormatException,
      );
    });
  });
}
