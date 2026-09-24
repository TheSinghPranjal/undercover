import 'dart:math';

import '../../../../core/utils/id_generator.dart';
import '../entities/player.dart';
import '../entities/player_assignment.dart';
import '../entities/round.dart';
import '../entities/word_entry.dart';
import 'game_rules.dart';

/// Deals a round. Pure logic – the only side input is [Random].
///
/// Imposter selection and starting-player selection are two independent
/// randomisations, so the starting player carries no signal about the
/// imposter.
class RoundGenerator {
  RoundGenerator({Random? random})
    : _random = random ?? Random.secure(),
      _ids = IdGenerator(random);

  final Random _random;
  final IdGenerator _ids;

  Round generate({
    required List<Player> players,
    required WordEntry word,
    required int imposterCount,
    required bool showHint,
    DateTime? now,
  }) {
    if (players.length < GameRules.minPlayers) {
      throw ArgumentError('At least ${GameRules.minPlayers} players required');
    }
    final ordered = [...players]
      ..sort((a, b) => a.position.compareTo(b.position));
    final count = GameRules.clampImposters(imposterCount, ordered.length);
    final imposterIds = pickImposterIds(ordered, count);

    final assignments = {
      for (final p in ordered)
        p.id: imposterIds.contains(p.id)
            ? PlayerAssignment.imposter(
                playerId: p.id,
                hint: showHint ? word.hint : null,
              )
            : PlayerAssignment.civilian(playerId: p.id, word: word.word),
    };

    return Round(
      id: _ids.next('round_'),
      word: word,
      players: List.unmodifiable(ordered),
      assignments: Map.unmodifiable(assignments),
      imposterIds: Set.unmodifiable(imposterIds),
      startingPlayerId: pickStartingPlayerId(ordered),
      showHint: showHint,
      createdAt: now ?? DateTime.now(),
    );
  }

  /// Uniformly picks [count] unique players from seat 3 onwards.
  Set<String> pickImposterIds(List<Player> orderedPlayers, int count) {
    final eligible = [
      for (var i = GameRules.protectedPositions; i < orderedPlayers.length; i++)
        orderedPlayers[i].id,
    ]..shuffle(_random);
    return eligible.take(count).toSet();
  }

  /// Any player may start, chosen uniformly and independently of roles.
  String pickStartingPlayerId(List<Player> players) =>
      players[_random.nextInt(players.length)].id;
}
