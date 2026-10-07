import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/ads/ad_config.dart';
import '../../../../core/ads/ads_service.dart';
import '../../../../core/services/haptics_service.dart';
import '../../../../core/services/privacy_service.dart';
import '../../../../core/services/sound_service.dart';
import '../../data/datasources/word_asset_datasource.dart';
import '../../data/repositories/prefs_settings_repository.dart';
import '../../data/repositories/word_repository_impl.dart';
import '../../domain/entities/game_settings.dart';
import '../../domain/entities/player.dart';
import '../../domain/entities/player_assignment.dart';
import '../../domain/enums/app_theme_preference.dart';
import '../../domain/enums/game_phase.dart';
import '../../domain/repositories/settings_repository.dart';
import '../../domain/repositories/word_repository.dart';
import '../../domain/services/game_rules.dart';
import '../../domain/services/recent_words_buffer.dart';
import '../../domain/services/round_generator.dart';
import '../../domain/services/word_pack_validator.dart';
import '../controllers/game_controller.dart';
import '../controllers/game_state.dart';
import '../controllers/settings_controller.dart';

// ------------------------------------------------------------ infrastructure

/// Overridden in `main()` with the loaded instance.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('sharedPreferencesProvider not overridden'),
);

final randomProvider = Provider<Random>((ref) => Random.secure());

final assetBundleProvider = Provider<AssetBundle>((ref) => rootBundle);

final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => PrefsSettingsRepository(ref.watch(sharedPreferencesProvider)),
);

final rosterRepositoryProvider = Provider<RosterRepository>(
  (ref) => PrefsRosterRepository(ref.watch(sharedPreferencesProvider)),
);

final hapticsProvider = Provider<HapticsService>(
  (ref) => HapticsService(
    enabled: ref.watch(gameSettingsProvider.select((s) => s.hapticsEnabled)),
  ),
);

final soundProvider = Provider<SoundService>(
  (ref) => SoundService(
    enabled: ref.watch(gameSettingsProvider.select((s) => s.soundEnabled)),
  ),
);

final privacyServiceProvider = Provider<PrivacyService>(
  (ref) => const PrivacyService(),
);

/// Overridden in `main()` with the instance that already ran UMP consent.
final adsServiceProvider = Provider<AdsService>((ref) {
  if (AdConfig.adsSupported) {
    return MobileAdsService(isTestMode: AdConfig.isTestMode);
  }
  return FakeAdsService();
});

// ------------------------------------------------------------ word pack

class WordPackException implements Exception {
  const WordPackException(this.details);
  final List<String> details;

  @override
  String toString() => 'Invalid word pack:\n${details.join('\n')}';
}

/// Loads, validates and indexes the bundled word pack exactly once.
final wordRepositoryProvider = FutureProvider<WordRepository>(
  (ref) async {
    final entries = await WordAssetDataSource(
      ref.watch(assetBundleProvider),
    ).load();
    final errors = WordPackValidator.validate(entries);
    if (errors.isNotEmpty) {
      // Debug builds surface the full list; the UI shows a friendly message.
      if (kDebugMode) debugPrint(WordPackException(errors).toString());
      throw WordPackException(errors);
    }
    return InMemoryWordRepository(entries, random: ref.watch(randomProvider));
  },
  // A broken bundled asset won't fix itself – don't retry.
  retry: (_, _) => null,
);

final recentWordsProvider = Provider<RecentWordsBuffer>(
  (ref) => RecentWordsBuffer(limit: GameRules.recentWordLimit),
);

final roundGeneratorProvider = Provider<RoundGenerator>(
  (ref) => RoundGenerator(random: ref.watch(randomProvider)),
);

// ------------------------------------------------------------ settings

final gameSettingsProvider = NotifierProvider<SettingsController, GameSettings>(
  SettingsController.new,
);

final themeModeProvider = Provider<ThemeMode>((ref) {
  return switch (ref.watch(gameSettingsProvider.select((s) => s.theme))) {
    AppThemePreference.system => ThemeMode.system,
    AppThemePreference.light => ThemeMode.light,
    AppThemePreference.dark => ThemeMode.dark,
  };
});

// ------------------------------------------------------------ game

final gameControllerProvider = NotifierProvider<GameController, GameState>(
  GameController.new,
);

final playersProvider = Provider<List<Player>>(
  (ref) => ref.watch(gameControllerProvider.select((s) => s.players)),
);

final gamePhaseProvider = Provider<GamePhase>(
  (ref) => ref.watch(gameControllerProvider.select((s) => s.phase)),
);

final maxImpostersProvider = Provider<int>(
  (ref) => GameRules.maxImposters(ref.watch(playersProvider).length),
);

/// The imposter count that will actually be dealt for the current group.
final effectiveImposterCountProvider = Provider<int>((ref) {
  final requested = ref.watch(
    gameSettingsProvider.select((s) => s.imposterCount),
  );
  return GameRules.clampImposters(requested, ref.watch(playersProvider).length);
});

/// The player currently holding the phone during the reveal flow.
final currentPlayerProvider = Provider<Player?>(
  (ref) => ref.watch(
    gameControllerProvider.select(
      (s) => s.round == null ? null : s.currentPlayer,
    ),
  ),
);

/// The current player's secret – and only while their card is face-up.
/// This is the only way presentation code can read an assignment.
final currentAssignmentProvider = Provider<PlayerAssignment?>(
  (ref) => ref.watch(
    gameControllerProvider.select(
      (s) => s.phase.exposesSecret ? s.currentAssignment : null,
    ),
  ),
);

/// (position, total) for the reveal progress indicator.
final revealProgressProvider = Provider<(int, int)>(
  (ref) => ref.watch(
    gameControllerProvider.select(
      (s) => (s.currentIndex + 1, s.round?.players.length ?? 0),
    ),
  ),
);

/// Only published once every card has been seen.
final startingPlayerProvider = Provider<Player?>(
  (ref) => ref.watch(
    gameControllerProvider.select(
      (s) => s.phase == GamePhase.roundReady ? s.round?.startingPlayer : null,
    ),
  ),
);
