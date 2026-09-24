/// Every state the game can be in. The [GameController] is the only thing
/// allowed to move between them.
enum GamePhase {
  playerSetup,
  configuration,
  generatingRound,

  /// "Pass the phone to X" – nothing secret on screen.
  passPhone,

  /// Face-down card is showing, waiting for a press & hold.
  readyToReveal,

  /// The current player is holding the card.
  revealing,

  /// The card is flipped and the secret is visible (not the last player).
  revealed,

  /// The card is flipping back before the phone moves on.
  passing,

  /// The last player's card is flipped – the button now says START GAME.
  allPlayersRevealed,

  /// The app was backgrounded while a secret was visible.
  privacyHidden,

  /// Every card has been seen; the starting player is announced.
  roundReady;

  /// Phases in which the current player's secret may be rendered.
  bool get exposesSecret =>
      this == revealed || this == allPlayersRevealed || this == passing;

  /// Phases that belong to an in-progress round (leaving needs confirmation).
  bool get isRevealFlow =>
      this == passPhone ||
      this == readyToReveal ||
      this == revealing ||
      this == revealed ||
      this == passing ||
      this == allPlayersRevealed ||
      this == privacyHidden;
}
