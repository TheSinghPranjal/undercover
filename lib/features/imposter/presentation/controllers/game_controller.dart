import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/ads/banner_gate.dart';
import '../../../../core/ads/interstitial_policy.dart';
import '../../../../core/utils/id_generator.dart';
import '../../domain/entities/player.dart';
import '../../domain/enums/game_phase.dart';
import '../../domain/services/game_rules.dart';
import '../../domain/services/player_validator.dart';
import '../providers/providers.dart';
import 'game_state.dart';

/// The single source of truth for the game. Widgets call these methods; they
/// never mutate game state themselves.
class GameController extends Notifier<GameState> {
  late final IdGenerator _ids = IdGenerator(ref.read(randomProvider));
  int _roundsCompleted = 0;
  DateTime? _lastInterstitialAt;

  @override
  GameState build() {
    final names = ref.read(rosterRepositoryProvider).loadNames();
    return GameState(
      phase: GamePhase.playerSetup,
      players: [
        for (final (i, name) in names.take(GameRules.maxPlayers).indexed)
          Player(id: _ids.next('p_'), name: name, position: i + 1),
      ],
    );
  }

  // ---------------------------------------------------------------- players

  bool get _allowDuplicates =>
      ref.read(gameSettingsProvider).allowDuplicateNames;

  PlayerNameError? validateName(String raw, {String? renamingId}) =>
      PlayerValidator.validate(
        raw,
        existing: state.players,
        allowDuplicates: _allowDuplicates,
        renamingId: renamingId,
      );

  /// Adds a player, or returns why it couldn't.
  PlayerNameError? addPlayer(String rawName) {
    final error = validateName(rawName);
    if (error != null) return error;
    final player = Player(
      id: _ids.next('p_'),
      name: PlayerValidator.normalize(rawName),
      position: state.players.length + 1,
    );
    _setPlayers([...state.players, player]);
    return null;
  }

  void removePlayer(String id) =>
      _setPlayers(state.players.where((p) => p.id != id).toList());

  PlayerNameError? renamePlayer(String id, String rawName) {
    final error = validateName(rawName, renamingId: id);
    if (error != null) return error;
    final name = PlayerValidator.normalize(rawName);
    _setPlayers([
      for (final p in state.players) p.id == id ? p.copyWith(name: name) : p,
    ]);
    return null;
  }

  void movePlayer(int oldIndex, int newIndex) {
    final list = [...state.players];
    final player = list.removeAt(oldIndex);
    list.insert(newIndex.clamp(0, list.length), player);
    _setPlayers(list);
  }

  void clearPlayers() => _setPlayers(const []);

  void _setPlayers(List<Player> players) {
    final renumbered = [
      for (final (i, p) in players.indexed) p.copyWith(position: i + 1),
    ];
    state = state.copyWith(players: renumbered, clearError: true);
    ref.read(rosterRepositoryProvider).saveNames([
      for (final p in renumbered) p.name,
    ]);
  }

  // ---------------------------------------------------------------- setup

  void goToPlayerSetup() =>
      state = state.copyWith(phase: GamePhase.playerSetup, clearRound: true);

  void goToConfiguration() {
    if (state.players.length < GameRules.minPlayers) return;
    state = state.copyWith(
      phase: GamePhase.configuration,
      clearRound: true,
      clearError: true,
    );
  }

  // ---------------------------------------------------------------- round

  /// Deals a fresh word, fresh imposters and a fresh starting player.
  Future<void> startRound() async {
    if (state.players.length < GameRules.minPlayers) return;
    if (state.phase == GamePhase.generatingRound) return;
    state = state.copyWith(
      phase: GamePhase.generatingRound,
      clearRound: true,
      currentIndex: 0,
      clearError: true,
    );
    try {
      final repository = await ref.read(wordRepositoryProvider.future);
      if (!ref.mounted) return;
      final settings = ref.read(gameSettingsProvider);
      final word = repository.getRandomWordForRound(
        settings.difficulty,
        ref.read(recentWordsProvider),
      );
      final round = ref
          .read(roundGeneratorProvider)
          .generate(
            players: state.players,
            word: word,
            imposterCount: settings.imposterCount,
            showHint: settings.showHint,
          );
      ref.read(privacyServiceProvider).setSecure(true);
      state = state.copyWith(
        phase: GamePhase.passPhone,
        round: round,
        currentIndex: 0,
      );
    } catch (_) {
      if (!ref.mounted) return;
      // Deliberately generic – never put round details in an error.
      state = state.copyWith(
        phase: GamePhase.configuration,
        clearRound: true,
        errorMessage: 'Something went wrong loading the word pack.',
      );
    }
  }

  /// "I'm ready" – the named player has the phone.
  void confirmReady() {
    if (state.phase == GamePhase.passPhone ||
        state.phase == GamePhase.privacyHidden) {
      state = state.copyWith(phase: GamePhase.readyToReveal);
    }
  }

  void beginHold() {
    if (state.phase == GamePhase.readyToReveal) {
      state = state.copyWith(phase: GamePhase.revealing);
    }
  }

  void cancelHold() {
    if (state.phase == GamePhase.revealing) {
      state = state.copyWith(phase: GamePhase.readyToReveal);
    }
  }

  void revealCurrentPlayer() {
    if (state.phase != GamePhase.revealing &&
        state.phase != GamePhase.readyToReveal) {
      return;
    }
    state = state.copyWith(
      phase: state.isLastPlayer
          ? GamePhase.allPlayersRevealed
          : GamePhase.revealed,
    );
  }

  /// Hides a visible secret (app backgrounded, screen locked…).
  void hideCurrentPlayer() {
    switch (state.phase) {
      case GamePhase.revealed:
      case GamePhase.allPlayersRevealed:
        state = state.copyWith(phase: GamePhase.privacyHidden);
      case GamePhase.revealing:
        state = state.copyWith(phase: GamePhase.readyToReveal);
      case GamePhase.passing:
        completePass();
      default:
        break;
    }
  }

  /// PASS TO NEXT PLAYER / START GAME. Starts flipping the card back;
  /// [completePass] moves on once the card is face-down, so a secret is never
  /// on screen while the view transitions.
  void passToNextPlayer() {
    if (state.phase == GamePhase.revealed ||
        state.phase == GamePhase.allPlayersRevealed) {
      state = state.copyWith(phase: GamePhase.passing);
    }
  }

  /// The card is face-down: hand over to the next player, or – after the
  /// last player – announce who starts.
  void completePass() {
    if (state.phase != GamePhase.passing) return;
    if (state.isLastPlayer) {
      ref.read(privacyServiceProvider).setSecure(false);
      state = state.copyWith(phase: GamePhase.roundReady);
    } else {
      state = state.copyWith(
        phase: GamePhase.passPhone,
        currentIndex: state.currentIndex + 1,
      );
    }
  }

  /// START GAME on the final player's card.
  void finishRevealPhase() {
    if (state.phase == GamePhase.allPlayersRevealed) passToNextPlayer();
  }

  /// Another round, after discussion. May show an interstitial first.
  ///
  /// The ad is only considered while the phase is still [GamePhase.roundReady],
  /// which is after every secret has been hidden. It is never shown from the
  /// pass-the-phone reveal.
  Future<void> startNextRound() async {
    if (state.phase != GamePhase.roundReady) return;
    ref.read(anchoredBannerSuppressProvider.notifier).setSuppressed(true);
    _roundsCompleted += 1;
    final showAd = InterstitialPolicy.shouldShow(
      fromNextRound: true,
      skipNext: false,
      roundsPlayed: _roundsCompleted,
      lastShownAt: _lastInterstitialAt,
      now: DateTime.now(),
    );
    if (showAd) {
      final shown = await ref.read(adsServiceProvider).showInterstitial();
      if (!ref.mounted) return;
      if (shown) _lastInterstitialAt = DateTime.now();
      if (state.phase != GamePhase.roundReady) {
        ref.read(anchoredBannerSuppressProvider.notifier).setSuppressed(false);
        return;
      }
    }
    try {
      await startRound();
    } finally {
      if (ref.mounted) {
        ref.read(anchoredBannerSuppressProvider.notifier).setSuppressed(false);
      }
    }
  }

  /// Discards the current round and returns to configuration.
  void exitRound() {
    ref.read(privacyServiceProvider).setSecure(false);
    state = state.copyWith(
      phase: GamePhase.configuration,
      clearRound: true,
      currentIndex: 0,
    );
  }

  void resetGame() {
    ref.read(privacyServiceProvider).setSecure(false);
    state = state.copyWith(
      phase: GamePhase.playerSetup,
      clearRound: true,
      currentIndex: 0,
    );
  }

  void clearError() => state = state.copyWith(clearError: true);
}
