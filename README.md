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

## Ads

Banners sit on the home menu and on the between-rounds "everyone's ready" screen. An interstitial can appear when the group taps **AGAIN**, every 4th round and not again for 90 seconds. No ad is shown during the pass-the-phone role and word reveal. There is no rewarded ad: the game has no extra life, hint unlock, or other reward an ad could fairly grant.

On launch the app requests UMP consent before initializing Mobile Ads. If a privacy-options entry point is required, Settings shows **Ad privacy choices**.

## Configuring AdMob for release

Debug and profile builds always request Google's sample ad units, so they show **Test Ad**. Release builds (`flutter build appbundle`, `flutter build ipa`, `flutter run --release`) request the production IDs in [`config/admob.json`](config/admob.json). That file is the only place to paste them. The publisher account is `pub-8661918790125012`.

Create the apps and ad units in AdMob, then replace each `TODO_…` value:

| JSON key | What to paste | Format | Where it is used |
| --- | --- | --- | --- |
| `ADMOB_ANDROID_APP_ID` | Android app `com.the_lazy_bear_club.undercover` → App settings → App ID | `ca-app-pub-8661918790125012~##########` | Android manifest, release builds |
| `ADMOB_ANDROID_BANNER_ID` | Android banner ad unit | `ca-app-pub-8661918790125012/##########` | Home menu and the between-rounds screen |
| `ADMOB_ANDROID_INTERSTITIAL_ID` | Android interstitial ad unit | `ca-app-pub-8661918790125012/##########` | Between rounds (every 4th **AGAIN**, 90 seconds apart) |
| `ADMOB_IOS_APP_ID` | iOS app `com.thelazybearclub.undercover` → App settings → App ID | `ca-app-pub-8661918790125012~##########` | `Info.plist` via `ios/Flutter/AdMob.xcconfig` |
| `ADMOB_IOS_BANNER_ID` | iOS banner ad unit | `ca-app-pub-8661918790125012/##########` | Home menu and the between-rounds screen |
| `ADMOB_IOS_INTERSTITIAL_ID` | iOS interstitial ad unit | `ca-app-pub-8661918790125012/##########` | Between rounds (every 4th **AGAIN**, 90 seconds apart) |

Where those values are applied:

- **Dart ad units** read `config/admob.json` (it is a bundled asset). You can override any key at compile time with `--dart-define` or `--dart-define-from-file=config/admob.json`. The keys are the same names as in the JSON file.
- **Android App ID** is injected into `AndroidManifest.xml` as `${admobAppId}`. Gradle reads `ADMOB_ANDROID_APP_ID` from the JSON for release, and Google's sample App ID for debug and profile.
- **iOS App ID** is `$(GAD_APPLICATION_IDENTIFIER)` in `ios/Runner/Info.plist`. Debug and profile xcconfigs pin the sample App ID. Release reads `ios/Flutter/AdMob.xcconfig`, which is generated from the JSON:

```bash
dart run tool/sync_admob.dart
```

Run that after every edit to the iOS App ID. A release iOS build fails if the xcconfig is stale.

Release builds also fail, instead of silently shipping test ads, when an ID is empty, still a `TODO_…` placeholder, or still one of Google's sample IDs (`ca-app-pub-3940256099942544…`):

- `flutter build appbundle` / `flutter build apk --release` runs `dart run tool/validate_admob.dart --android` before packaging.
- Xcode Release runs `tool/validate_admob_ios.sh`.
- The release app itself throws on startup if the current platform's IDs are still invalid.

Android can ship before the iOS IDs exist. The Android check only looks at the three Android keys, and the iOS check only looks at the three iOS keys. An Android release build passes that check once the Android keys are real, even while the iOS keys are still `TODO_…`. An iOS release build keeps failing until those iOS keys are replaced.

## Privacy

- Widgets never get the whole round. `currentAssignmentProvider` exposes only the current player's card, and only while it's face-up.
- The secret side of the card is only built once the card has turned past 90°. It flips face-down before the phone moves to the next player.
- If the app is backgrounded or goes inactive while a card is visible, the card is hidden. The player has to confirm and hold again.
- Android sets `FLAG_SECURE` during a round, which blocks screenshots and blanks the recent-apps preview (`MainActivity.kt`).
- `Round`, `WordEntry`, `PlayerAssignment` and `GameState` override `toString()` so the word never shows up in logs. Rounds are never saved; only settings and player names are.

## Word pack

`assets/data/imposter_words.json` holds 200 easy, 200 medium and 200 difficult entries across 22 categories. Each has an `id`, `difficulty`, `category`, `word`, `hint` and `tags`, plus an optional `alternateHint`. The pack is checked on every launch. In debug builds a bad pack prints the full list of problems. In release builds the player sees a friendly error screen instead.
