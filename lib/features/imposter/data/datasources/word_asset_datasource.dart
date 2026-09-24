import 'dart:convert';

import 'package:flutter/services.dart';

import '../../domain/entities/word_entry.dart';
import '../models/word_entry_model.dart';

class WordAssetDataSource {
  WordAssetDataSource(this._bundle);

  static const String assetPath = 'assets/data/imposter_words.json';

  final AssetBundle _bundle;

  Future<List<WordEntry>> load() async {
    final raw = await _bundle.loadString(assetPath);
    return parse(raw);
  }

  static List<WordEntry> parse(String raw) {
    final decoded = jsonDecode(raw);
    final list = decoded is Map<String, dynamic> ? decoded['words'] : decoded;
    if (list is! List) {
      throw const FormatException('Word pack must contain a "words" list');
    }
    return [
      for (final item in list)
        WordEntryModel.fromJson(item as Map<String, dynamic>),
    ];
  }
}
