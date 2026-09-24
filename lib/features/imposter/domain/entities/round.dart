import 'package:flutter/foundation.dart';

import '../enums/difficulty.dart';
import 'player.dart';
import 'player_assignment.dart';
import 'word_entry.dart';

/// A fully dealt round. Held only by the game controller – presentation code
/// should read the current player's assignment through dedicated providers.
@immutable
class Round {
  const Round({
    required this.id,
    required this.word,
    required this.players,
    required this.assignments,
    required this.imposterIds,
    required this.startingPlayerId,
    required this.showHint,
    required this.createdAt,
  });

  final String id;
  final WordEntry word;
  final List<Player> players;
  final Map<String, PlayerAssignment> assignments;
  final Set<String> imposterIds;
  final String startingPlayerId;
  final bool showHint;
  final DateTime createdAt;

  String get secretWord => word.word;
  Difficulty get difficulty => word.difficulty;

  PlayerAssignment assignmentFor(String playerId) => assignments[playerId]!;

  Player get startingPlayer =>
      players.firstWhere((p) => p.id == startingPlayerId);

  // Never leak secrets through logs.
  @override
  String toString() => 'Round($id, ${players.length} players, <redacted>)';
}
