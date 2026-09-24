import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/game_settings.dart';
import '../../domain/enums/app_theme_preference.dart';
import '../../domain/enums/difficulty.dart';
import '../providers/providers.dart';

/// Persisted preferences. The configuration screen writes through to here so
/// the group's last choices are remembered.
class SettingsController extends Notifier<GameSettings> {
  @override
  GameSettings build() => ref.read(settingsRepositoryProvider).load();

  void _update(GameSettings next) {
    if (next == state) return;
    state = next;
    ref.read(settingsRepositoryProvider).save(next);
  }

  void setDifficulty(Difficulty v) => _update(state.copyWith(difficulty: v));
  void setImposterCount(int v) =>
      _update(state.copyWith(imposterCount: v < 1 ? 1 : v));
  void setShowHint(bool v) => _update(state.copyWith(showHint: v));
  void setTheme(AppThemePreference v) => _update(state.copyWith(theme: v));
  void setSound(bool v) => _update(state.copyWith(soundEnabled: v));
  void setHaptics(bool v) => _update(state.copyWith(hapticsEnabled: v));
  void setAnimations(bool v) => _update(state.copyWith(animationsEnabled: v));
  void setAllowDuplicateNames(bool v) =>
      _update(state.copyWith(allowDuplicateNames: v));
  void setTapToReveal(bool v) => _update(state.copyWith(tapToReveal: v));

  Future<void> reset() async {
    await ref.read(settingsRepositoryProvider).clear();
    state = const GameSettings();
  }
}
