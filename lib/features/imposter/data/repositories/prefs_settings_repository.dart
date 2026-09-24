import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/game_settings.dart';
import '../../domain/enums/app_theme_preference.dart';
import '../../domain/enums/difficulty.dart';
import '../../domain/repositories/settings_repository.dart';

class PrefsSettingsRepository implements SettingsRepository {
  PrefsSettingsRepository(this._prefs);

  final SharedPreferences _prefs;

  static const _prefix = 'settings.';
  static const _difficulty = '${_prefix}difficulty';
  static const _imposters = '${_prefix}imposterCount';
  static const _showHint = '${_prefix}showHint';
  static const _theme = '${_prefix}theme';
  static const _sound = '${_prefix}sound';
  static const _haptics = '${_prefix}haptics';
  static const _animations = '${_prefix}animations';
  static const _duplicates = '${_prefix}allowDuplicateNames';
  static const _tapToReveal = '${_prefix}tapToReveal';

  static const _keys = [
    _difficulty,
    _imposters,
    _showHint,
    _theme,
    _sound,
    _haptics,
    _animations,
    _duplicates,
    _tapToReveal,
  ];

  @override
  GameSettings load() {
    const d = GameSettings();
    return GameSettings(
      difficulty:
          Difficulty.fromKey(_prefs.getString(_difficulty)) ?? d.difficulty,
      imposterCount: _prefs.getInt(_imposters) ?? d.imposterCount,
      showHint: _prefs.getBool(_showHint) ?? d.showHint,
      theme: AppThemePreference.fromKey(_prefs.getString(_theme)),
      soundEnabled: _prefs.getBool(_sound) ?? d.soundEnabled,
      hapticsEnabled: _prefs.getBool(_haptics) ?? d.hapticsEnabled,
      animationsEnabled: _prefs.getBool(_animations) ?? d.animationsEnabled,
      allowDuplicateNames: _prefs.getBool(_duplicates) ?? d.allowDuplicateNames,
      tapToReveal: _prefs.getBool(_tapToReveal) ?? d.tapToReveal,
    );
  }

  @override
  Future<void> save(GameSettings s) async {
    await Future.wait([
      _prefs.setString(_difficulty, s.difficulty.key),
      _prefs.setInt(_imposters, s.imposterCount),
      _prefs.setBool(_showHint, s.showHint),
      _prefs.setString(_theme, s.theme.key),
      _prefs.setBool(_sound, s.soundEnabled),
      _prefs.setBool(_haptics, s.hapticsEnabled),
      _prefs.setBool(_animations, s.animationsEnabled),
      _prefs.setBool(_duplicates, s.allowDuplicateNames),
      _prefs.setBool(_tapToReveal, s.tapToReveal),
    ]);
  }

  @override
  Future<void> clear() async {
    await Future.wait(_keys.map(_prefs.remove));
  }
}

class PrefsRosterRepository implements RosterRepository {
  PrefsRosterRepository(this._prefs);

  final SharedPreferences _prefs;
  static const _key = 'roster.names';

  @override
  List<String> loadNames() => _prefs.getStringList(_key) ?? const [];

  @override
  Future<void> saveNames(List<String> names) =>
      _prefs.setStringList(_key, names);
}
