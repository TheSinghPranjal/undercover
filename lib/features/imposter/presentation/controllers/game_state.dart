import 'package:flutter/foundation.dart';

import '../../domain/entities/player.dart';
import '../../domain/entities/player_assignment.dart';
import '../../domain/entities/round.dart';
import '../../domain/enums/game_phase.dart';

@immutable
class GameState {
  const GameState({
    required this.phase,
    required this.players,
    this.round,
    this.currentIndex = 0,
    this.errorMessage,
  });

  final GamePhase phase;
  final List<Player> players;

  /// The dealt round. Private to the controller and its derived providers.
  final Round? round;

  /// Index into [Round.players] of the player holding the phone.
  final int currentIndex;
  final String? errorMessage;

  Player? get currentPlayer {
    final r = round;
    if (r == null || currentIndex >= r.players.length) return null;
    return r.players[currentIndex];
  }

  PlayerAssignment? get currentAssignment {
    final p = currentPlayer;
    return p == null ? null : round!.assignmentFor(p.id);
  }

  bool get isLastPlayer =>
      round != null && currentIndex == round!.players.length - 1;

  GameState copyWith({
    GamePhase? phase,
    List<Player>? players,
    Round? round,
    bool clearRound = false,
    int? currentIndex,
    String? errorMessage,
    bool clearError = false,
  }) => GameState(
    phase: phase ?? this.phase,
    players: players ?? this.players,
    round: clearRound ? null : (round ?? this.round),
    currentIndex: currentIndex ?? this.currentIndex,
    errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
  );

  // Never leak secrets through logs.
  @override
  String toString() =>
      'GameState($phase, ${players.length} players, index $currentIndex)';
}
