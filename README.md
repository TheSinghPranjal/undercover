# Find the Imposter

A pass-the-phone party game for 3–20 players. Everyone gets the same secret word, except the imposter. Players reveal their cards one at a time on a single phone, then put it down and play out loud.

The app deals the round, handles the private reveal and announces who gives the first clue. Clues, discussion and voting happen away from the app.

## Run

```sh
flutter pub get
flutter run
```

Works offline. The 600-word pack is bundled in `assets/data/imposter_words.json`.

## Test

```sh
flutter test                                   # unit + widget tests
flutter test integration_test -d <device-id>   # full game flow on a device/simulator
```

## Game rules in code

| Rule | Where |
| --- | --- |
| 3–20 players, name length, 1 imposter per 3 players | `domain/services/game_rules.dart` |
| Seats 1 and 2 are never imposters | `RoundGenerator.pickImposterIds` |
| Starting player is random and independent of roles | `RoundGenerator.pickStartingPlayerId` |
| No word repeats within the last 20 rounds | `InMemoryWordRepository.getRandomWordForRound` |
| Word-pack validation (counts, duplicates, hint leaks) | `domain/services/word_pack_validator.dart` |

## Architecture

```
lib/
  app/            MaterialApp, theme tokens (colors, type, spacing), routes
  core/           services (haptics, sound, privacy), shared widgets, id generator
  features/imposter/
    domain/       entities, enums, repository interfaces, pure game logic
    data/         JSON parsing, asset loading, SharedPreferences repositories
    presentation/ Riverpod providers, GameController, screens, widgets
```

`GameController` (a Riverpod `Notifier`) is the only thing that changes game state. It moves through an explicit `GamePhase` state machine:

```
playerSetup → configuration → generatingRound → passPhone → readyToReveal
  → revealing → revealed → passing → passPhone …        (every player but the last)
  → revealing → allPlayersRevealed → passing → roundReady (last player)
  → startNextRound → generatingRound …
```

`privacyHidden` can come in from any reveal state when the app leaves the foreground.

## Privacy

- Widgets never get the whole round. `currentAssignmentProvider` exposes only the current player's card, and only while it's face-up.
- The secret side of the card is only built once the card has turned past 90°. It flips face-down before the phone moves to the next player.
- If the app is backgrounded or goes inactive while a card is visible, the card is hidden. The player has to confirm and hold again.
- Android sets `FLAG_SECURE` during a round, which blocks screenshots and blanks the recent-apps preview (`MainActivity.kt`).
- `Round`, `WordEntry`, `PlayerAssignment` and `GameState` override `toString()` so the word never shows up in logs. Rounds are never saved; only settings and player names are.

## Word pack

`assets/data/imposter_words.json` holds 200 easy, 200 medium and 200 difficult entries across 22 categories. Each has an `id`, `difficulty`, `category`, `word`, `hint` and `tags`, plus an optional `alternateHint`. The pack is checked on every launch. In debug builds a bad pack prints the full list of problems. In release builds the player sees a friendly error screen instead.
