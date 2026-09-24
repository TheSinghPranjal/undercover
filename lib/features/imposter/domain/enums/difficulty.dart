/// How hard the secret word is to infer for an imposter who only has a hint.
enum Difficulty {
  easy('easy'),
  medium('medium'),
  difficult('difficult');

  const Difficulty(this.key);

  /// Stable key used in the word pack and in persisted settings.
  final String key;

  static Difficulty? fromKey(String? key) {
    for (final d in values) {
      if (d.key == key) return d;
    }
    return null;
  }
}
