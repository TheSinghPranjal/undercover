import 'package:flutter_test/flutter_test.dart';
import 'package:undercover/features/imposter/domain/enums/difficulty.dart';
import 'package:undercover/features/imposter/presentation/providers/providers.dart';
import 'package:undercover/features/imposter/presentation/screens/game_config_screen.dart';

import '../helpers/test_helpers.dart';

void main() {
  Map<String, Object> roster(int n) => {
    'roster.names': [for (var i = 1; i <= n; i++) 'Player $i'],
  };

  testWidgets('defaults and dynamic imposter maximum', (tester) async {
    final c = await pumpApp(tester, const GameConfigScreen(), prefs: roster(8));
    expect(find.text('READY TO PLAY?'), findsOneWidget);
    expect(find.text('Maximum imposters for 8 players: 2'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('More imposters'));
    await tester.pumpAndSettle();
    expect(c.read(gameSettingsProvider).imposterCount, 2);

    // At the max the + button is disabled.
    await tester.tap(find.bySemanticsLabel('More imposters'));
    await tester.pumpAndSettle();
    expect(c.read(gameSettingsProvider).imposterCount, 2);
  });

  testWidgets('difficulty and hint toggle update settings', (tester) async {
    final c = await pumpApp(tester, const GameConfigScreen(), prefs: roster(5));
    expect(c.read(gameSettingsProvider).difficulty, Difficulty.easy);
    expect(c.read(gameSettingsProvider).showHint, isFalse);

    await tester.tap(find.bySemanticsLabel('Difficult difficulty'));
    await tester.pumpAndSettle();
    expect(c.read(gameSettingsProvider).difficulty, Difficulty.difficult);

    await tester.ensureVisible(find.text('Show hint to imposter'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Show hint to imposter'));
    await tester.pumpAndSettle();
    expect(c.read(gameSettingsProvider).showHint, isTrue);
  });

  testWidgets('5 players cannot go above 1 imposter', (tester) async {
    final c = await pumpApp(tester, const GameConfigScreen(), prefs: roster(5));
    expect(find.text('Maximum imposters for 5 players: 1'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('More imposters'));
    await tester.pumpAndSettle();
    expect(c.read(effectiveImposterCountProvider), 1);
  });
}
