import '../../domain/enums/difficulty.dart';
import '../../domain/services/game_rules.dart';
import '../../domain/services/player_validator.dart';

extension DifficultyLabels on Difficulty {
  String get label => switch (this) {
    Difficulty.easy => 'Easy',
    Difficulty.medium => 'Medium',
    Difficulty.difficult => 'Difficult',
  };

  String get emoji => switch (this) {
    Difficulty.easy => '🟢',
    Difficulty.medium => '🟡',
    Difficulty.difficult => '🔴',
  };

  String get blurb => switch (this) {
    Difficulty.easy => 'Everyday words. Perfect for a first round.',
    Difficulty.medium => 'Trickier words with room to bluff.',
    Difficulty.difficult => 'Specific words. Imposters beware.',
  };
}

extension PlayerNameErrorMessage on PlayerNameError {
  String get message => switch (this) {
    PlayerNameError.empty => 'Type a name first.',
    PlayerNameError.tooLong =>
      'Keep it to ${GameRules.maxNameLength} characters.',
    PlayerNameError.duplicate => "Two players can't have the same name.",
    PlayerNameError.tooManyPlayers =>
      "That's a full house – ${GameRules.maxPlayers} players max.",
  };
}
