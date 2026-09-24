import 'package:flutter/foundation.dart';

import '../enums/difficulty.dart';

@immutable
class WordEntry {
  const WordEntry({
    required this.id,
    required this.difficulty,
    required this.category,
    required this.word,
    required this.hint,
    this.alternateHint,
    this.tags = const [],
  });

  final String id;
  final Difficulty difficulty;
  final String category;
  final String word;
  final String hint;
  final String? alternateHint;
  final List<String> tags;

  // Never leak secrets through logs.
  @override
  String toString() => 'WordEntry($id)';
}
