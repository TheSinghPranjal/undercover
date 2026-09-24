import '../entities/word_entry.dart';
import '../enums/difficulty.dart';
import '../services/recent_words_buffer.dart';

abstract interface class WordRepository {
  List<WordEntry> get allWords;

  List<WordEntry> getWordsByDifficulty(Difficulty difficulty);

  WordEntry getRandomWord(Difficulty difficulty);

  /// Picks a word whose id is not in [excludedIds]. Falls back to the full
  /// pool if everything is excluded.
  WordEntry getRandomWordExcluding(
    Difficulty difficulty,
    Set<String> excludedIds,
  );

  /// Picks a word that hasn't been used recently and records it in [recent].
  /// When every word is recent, the oldest entries are recycled first.
  WordEntry getRandomWordForRound(
    Difficulty difficulty,
    RecentWordsBuffer recent,
  );
}
