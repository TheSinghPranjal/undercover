import '../entities/word_entry.dart';
import '../enums/difficulty.dart';

/// Checks the bundled word pack. Returns a list of human-readable problems;
/// an empty list means the pack is valid.
abstract final class WordPackValidator {
  static const int wordsPerDifficulty = 200;

  static const Set<String> categories = {
    'food',
    'animals',
    'nature',
    'weather',
    'places',
    'travel',
    'household',
    'transport',
    'clothing',
    'body',
    'sports',
    'school',
    'technology',
    'music',
    'entertainment',
    'activities',
    'celebrations',
    'games',
    'professions',
    'space',
    'science',
    'work',
  };

  static List<String> validate(
    List<WordEntry> entries, {
    int perDifficulty = wordsPerDifficulty,
  }) {
    final errors = <String>[];
    final expectedTotal = perDifficulty * Difficulty.values.length;
    if (entries.length != expectedTotal) {
      errors.add('Expected $expectedTotal words, found ${entries.length}');
    }
    for (final d in Difficulty.values) {
      final n = entries.where((e) => e.difficulty == d).length;
      if (n != perDifficulty) {
        errors.add('Expected $perDifficulty ${d.key} words, found $n');
      }
    }

    final ids = <String>{};
    final words = <String, String>{};
    for (final e in entries) {
      if (e.id.trim().isEmpty) errors.add('Entry with empty id');
      if (!ids.add(e.id)) errors.add('Duplicate id ${e.id}');
      if (e.word.trim().isEmpty) errors.add('${e.id}: empty word');
      if (e.hint.trim().isEmpty) errors.add('${e.id}: empty hint');
      if (!categories.contains(e.category)) {
        errors.add('${e.id}: unknown category "${e.category}"');
      }
      final key = _letters(e.word);
      final previous = words[key];
      if (previous != null) errors.add('${e.id}: duplicate of $previous');
      words[key] = e.id;

      if (hintGivesAwayWord(e.word, e.hint)) {
        errors.add('${e.id}: hint gives away the word');
      }
      final alt = e.alternateHint;
      if (alt != null && hintGivesAwayWord(e.word, alt)) {
        errors.add('${e.id}: alternate hint gives away the word');
      }
    }
    return errors;
  }

  /// True when the hint equals, contains or is contained in the word, or when
  /// they share a word (ignoring plurals) – e.g. Water / "Water bottle".
  static bool hintGivesAwayWord(String word, String hint) {
    final w = _letters(word);
    final h = _letters(hint);
    if (w.isEmpty || h.isEmpty) return true;
    if (w == h || h.contains(w) || w.contains(h)) return true;
    final wordTokens = _tokens(word);
    return _tokens(hint).any(wordTokens.contains);
  }

  static String _letters(String s) =>
      s.toLowerCase().replaceAll(RegExp('[^a-z0-9]'), '');

  static Set<String> _tokens(String s) => RegExp(
    '[a-z0-9]+',
  ).allMatches(s.toLowerCase()).map((m) => _singular(m.group(0)!)).toSet();

  static String _singular(String t) =>
      t.length > 3 && t.endsWith('s') ? t.substring(0, t.length - 1) : t;
}
