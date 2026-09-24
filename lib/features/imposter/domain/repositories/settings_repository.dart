import '../entities/game_settings.dart';

abstract interface class SettingsRepository {
  GameSettings load();
  Future<void> save(GameSettings settings);
  Future<void> clear();
}

/// Remembers the last group of players so a returning group can jump in.
/// Only names are stored – never round assignments.
abstract interface class RosterRepository {
  List<String> loadNames();
  Future<void> saveNames(List<String> names);
}
