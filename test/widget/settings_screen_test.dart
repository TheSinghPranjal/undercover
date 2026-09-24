import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:undercover/features/imposter/domain/enums/app_theme_preference.dart';
import 'package:undercover/features/imposter/domain/enums/difficulty.dart';
import 'package:undercover/features/imposter/presentation/providers/providers.dart';
import 'package:undercover/features/imposter/presentation/screens/settings_screen.dart';

import '../helpers/test_helpers.dart';

void main() {
  testWidgets('changes are applied and persisted', (tester) async {
    final c = await pumpApp(tester, const SettingsScreen());
    expect(find.text('GAME SETTINGS'), findsOneWidget);

    await tester.tap(find.text('Medium'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();

    expect(c.read(gameSettingsProvider).difficulty, Difficulty.medium);
    expect(c.read(gameSettingsProvider).theme, AppThemePreference.dark);
    expect(
      Theme.of(tester.element(find.byType(SettingsScreen))).brightness,
      Brightness.dark,
    );

    final prefs = c.read(sharedPreferencesProvider);
    expect(prefs.getString('settings.difficulty'), 'medium');
    expect(prefs.getString('settings.theme'), 'dark');
  });

  testWidgets('reset restores defaults after confirmation', (tester) async {
    final c = await pumpApp(
      tester,
      const SettingsScreen(),
      prefs: {'settings.difficulty': 'difficult', 'settings.showHint': true},
    );
    expect(c.read(gameSettingsProvider).difficulty, Difficulty.difficult);

    await tester.scrollUntilVisible(find.text('Reset settings'), 200);
    await tester.ensureVisible(find.text('Reset settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reset settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('RESET'));
    await tester.pumpAndSettle();

    expect(c.read(gameSettingsProvider).difficulty, Difficulty.easy);
    expect(c.read(gameSettingsProvider).showHint, isFalse);
  });
}
