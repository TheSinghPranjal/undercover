import 'dart:math';

import '../../domain/entities/word_entry.dart';
import '../../domain/enums/difficulty.dart';
import '../../domain/repositories/word_repository.dart';
import '../../domain/services/recent_words_buffer.dart';

/// Word pack held in memory. Parsed once, then indexed by difficulty.
class InMemoryWordRepository implements WordRepository {
  InMemoryWordRepository(List<WordEntry> entries, {Random? random})
    : _all = List.unmodifiable(entries),
      _random = random ?? Random.secure(),
      _byDifficulty = {
        for (final d in Difficulty.values)
          d: List.unmodifiable(entries.where((e) => e.difficulty == d)),
      };

  final List<WordEntry> _all;
  final Map<Difficulty, List<WordEntry>> _byDifficulty;
  final Random _random;

  @override
  List<WordEntry> get allWords => _all;

  @override
  List<WordEntry> getWordsByDifficulty(Difficulty difficulty) =>
      _byDifficulty[difficulty]!;

  @override
  WordEntry getRandomWord(Difficulty difficulty) =>
      _pick(_nonEmptyPool(difficulty));

  @override
  WordEntry getRandomWordExcluding(
    Difficulty difficulty,
    Set<String> excludedIds,
  ) {
    final pool = _nonEmptyPool(difficulty);
    final available = pool.where((e) => !excludedIds.contains(e.id)).toList();
    return _pick(available.isEmpty ? pool : available);
  }

  @override
  WordEntry getRandomWordForRound(
    Difficulty difficulty,
    RecentWordsBuffer recent,
  ) {
    final pool = _nonEmptyPool(difficulty);
    var available = pool.where((e) => !recent.contains(e.id)).toList();
    // Recycle the oldest words first, but never deal the very last word again
    // when there is any alternative.
    while (available.isEmpty && recent.length > 1) {
      recent.dropOldest();
      available = pool.where((e) => !recent.contains(e.id)).toList();
    }
    final word = _pick(available.isEmpty ? pool : available);
    recent.add(word.id);
    return word;
  }

  List<WordEntry> _nonEmptyPool(Difficulty difficulty) {
    final pool = _byDifficulty[difficulty]!;
    if (pool.isEmpty) {
      throw StateError('No words available for ${difficulty.key}');
    }
    return pool;
  }

  WordEntry _pick(List<WordEntry> pool) => pool[_random.nextInt(pool.length)];
}
