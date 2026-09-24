import '../../domain/entities/word_entry.dart';
import '../../domain/enums/difficulty.dart';

/// JSON mapping for [WordEntry].
abstract final class WordEntryModel {
  static WordEntry fromJson(Map<String, dynamic> json) {
    final difficulty = Difficulty.fromKey(json['difficulty'] as String?);
    if (difficulty == null) {
      throw FormatException(
        'Invalid difficulty "${json['difficulty']}" for ${json['id']}',
      );
    }
    return WordEntry(
      id: _string(json, 'id'),
      difficulty: difficulty,
      category: _string(json, 'category'),
      word: _string(json, 'word'),
      hint: _string(json, 'hint'),
      alternateHint: json['alternateHint'] as String?,
      tags: [for (final t in (json['tags'] as List? ?? const [])) t as String],
    );
  }

  static String _string(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is! String) {
      throw FormatException('Missing "$key" in word entry ${json['id']}');
    }
    return value.trim();
  }
}
