import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:undercover/features/imposter/data/repositories/word_repository_impl.dart';
import 'package:undercover/features/imposter/domain/entities/word_entry.dart';
import 'package:undercover/features/imposter/domain/enums/difficulty.dart';
import 'package:undercover/features/imposter/domain/services/recent_words_buffer.dart';

import '../helpers/test_helpers.dart';

void main() {
  final repo = InMemoryWordRepository(realWordPack(), random: Random(3));

  test('filters by difficulty', () {
    for (final d in Difficulty.values) {
      expect(repo.getWordsByDifficulty(d), hasLength(200));
      expect(
        repo.getWordsByDifficulty(d).every((e) => e.difficulty == d),
        isTrue,
      );
      for (var i = 0; i < 50; i++) {
        expect(repo.getRandomWord(d).difficulty, d);
      }
    }
  });

  test('getRandomWordExcluding skips excluded ids', () {
    final easy = repo.getWordsByDifficulty(Difficulty.easy);
    final keep = easy.first;
    final excluded = easy.skip(1).map((e) => e.id).toSet();
    for (var i = 0; i < 20; i++) {
      expect(
        repo.getRandomWordExcluding(Difficulty.easy, excluded).id,
        keep.id,
      );
    }
  });

  test('never repeats a word within the recent window', () {
    final recent = RecentWordsBuffer(limit: 20);
    final history = <String>[];
    for (var i = 0; i < 400; i++) {
      final w = repo.getRandomWordForRound(Difficulty.medium, recent);
      final window = history.length > 20
          ? history.sublist(history.length - 20)
          : history;
      expect(window, isNot(contains(w.id)));
      history.add(w.id);
    }
  });

  test('recycles the oldest words when the pool is exhausted', () {
    const words = [
      WordEntry(
        id: 'a',
        difficulty: Difficulty.easy,
        category: 'food',
        word: 'A',
        hint: 'x',
      ),
      WordEntry(
        id: 'b',
        difficulty: Difficulty.easy,
        category: 'food',
        word: 'B',
        hint: 'y',
      ),
      WordEntry(
        id: 'c',
        difficulty: Difficulty.easy,
        category: 'food',
        word: 'C',
        hint: 'z',
      ),
    ];
    final small = InMemoryWordRepository(words, random: Random(5));
    final recent = RecentWordsBuffer(limit: 20);
    String? previous;
    for (var i = 0; i < 30; i++) {
      final w = small.getRandomWordForRound(Difficulty.easy, recent);
      expect(w.id, isNot(previous), reason: 'no immediate repeat');
      previous = w.id;
    }
  });

  test('buffer keeps only the newest ids', () {
    final b = RecentWordsBuffer(limit: 3)
      ..add('1')
      ..add('2')
      ..add('3')
      ..add('4');
    expect(b.ids, {'2', '3', '4'});
    expect(b.mostRecent, '4');
    b.dropOldest();
    expect(b.ids, {'3', '4'});
  });
}
