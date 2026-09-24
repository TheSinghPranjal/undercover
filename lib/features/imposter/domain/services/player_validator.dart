import '../entities/player.dart';
import 'game_rules.dart';

enum PlayerNameError { empty, tooLong, duplicate, tooManyPlayers }

abstract final class PlayerValidator {
  /// Trims and collapses internal whitespace.
  static String normalize(String raw) =>
      raw.trim().replaceAll(RegExp(r'\s+'), ' ');

  static PlayerNameError? validate(
    String raw, {
    required List<Player> existing,
    required bool allowDuplicates,
    String? renamingId,
  }) {
    final name = normalize(raw);
    if (name.isEmpty) return PlayerNameError.empty;
    if (name.length > GameRules.maxNameLength) return PlayerNameError.tooLong;
    if (renamingId == null && existing.length >= GameRules.maxPlayers) {
      return PlayerNameError.tooManyPlayers;
    }
    if (!allowDuplicates) {
      final key = name.toLowerCase();
      final clash = existing.any(
        (p) => p.id != renamingId && p.name.toLowerCase() == key,
      );
      if (clash) return PlayerNameError.duplicate;
    }
    return null;
  }
}
