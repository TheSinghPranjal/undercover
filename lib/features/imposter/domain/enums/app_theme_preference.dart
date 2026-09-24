enum AppThemePreference {
  system('system'),
  light('light'),
  dark('dark');

  const AppThemePreference(this.key);

  final String key;

  static AppThemePreference fromKey(String? key) {
    for (final t in values) {
      if (t.key == key) return t;
    }
    return AppThemePreference.system;
  }
}
