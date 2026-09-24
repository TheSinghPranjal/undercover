import 'package:flutter/foundation.dart';

import '../enums/role.dart';

/// What a single player is allowed to see on their secret card.
@immutable
class PlayerAssignment {
  const PlayerAssignment.civilian({
    required this.playerId,
    required String this.word,
  }) : role = Role.civilian,
       hint = null;

  const PlayerAssignment.imposter({required this.playerId, this.hint})
    : role = Role.imposter,
      word = null;

  final String playerId;
  final Role role;

  /// The secret word. Always null for imposters.
  final String? word;

  /// Only set for imposters, and only when hints are enabled.
  final String? hint;

  bool get isImposter => role == Role.imposter;

  // Never leak secrets through logs.
  @override
  String toString() => 'PlayerAssignment(<redacted>)';
}
