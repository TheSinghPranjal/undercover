import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:undercover/features/imposter/presentation/providers/providers.dart';
import 'package:undercover/features/imposter/presentation/screens/game_config_screen.dart';
import 'package:undercover/features/imposter/presentation/screens/player_setup_screen.dart';

import '../helpers/test_helpers.dart';

Future<void> addPlayer(WidgetTester tester, String name) async {
  await tester.enterText(find.byType(TextField), name);
  await tester.tap(find.text('ADD'));
  await tester.pumpAndSettle();
}

FilledButton continueButton(WidgetTester tester) => tester.widget<FilledButton>(
  find.ancestor(of: find.text('CONTINUE'), matching: find.byType(FilledButton)),
);

void main() {
  testWidgets('empty state, adding players and enabling continue', (
    tester,
  ) async {
    final c = await pumpApp(tester, const PlayerSetupScreen());
    expect(find.text('Add at least 3 players to start.'), findsOneWidget);
    expect(continueButton(tester).onPressed, isNull);

    await addPlayer(tester, 'Rahul');
    await addPlayer(tester, '  Priya  ');
    expect(find.text('Add 1 more to start.'), findsOneWidget);
    expect(continueButton(tester).onPressed, isNull);

    await addPlayer(tester, 'Aman');
    expect(find.text('3 / 20 players'), findsOneWidget);
    expect(find.text('Best with 4–10 players'), findsOneWidget);
    expect(find.text('Priya'), findsOneWidget);
    expect(continueButton(tester).onPressed, isNotNull);
    expect(c.read(playersProvider).map((p) => p.name), [
      'Rahul',
      'Priya',
      'Aman',
    ]);

    await tester.tap(find.text('CONTINUE'));
    await tester.pumpAndSettle();
    expect(find.byType(GameConfigScreen), findsOneWidget);
  });

  testWidgets('duplicate names show immediate feedback', (tester) async {
    await pumpApp(tester, const PlayerSetupScreen());
    await addPlayer(tester, 'Rahul');
    await tester.enterText(find.byType(TextField), 'rahul');
    await tester.pump();
    expect(find.text("Two players can't have the same name."), findsOneWidget);
    await tester.tap(find.text('ADD'));
    await tester.pumpAndSettle();
    expect(find.text('Rahul'), findsOneWidget);
    expect(find.text('1 / 20 players'), findsOneWidget);
  });

  testWidgets('empty name is rejected on submit', (tester) async {
    await pumpApp(tester, const PlayerSetupScreen());
    await tester.tap(find.text('ADD'));
    await tester.pumpAndSettle();
    expect(find.text('Type a name first.'), findsOneWidget);
  });

  testWidgets('removing a player renumbers the rest', (tester) async {
    final c = await pumpApp(tester, const PlayerSetupScreen());
    for (final n in ['Rahul', 'Priya', 'Aman']) {
      await addPlayer(tester, n);
    }
    await tester.tap(find.byTooltip('Remove Priya'));
    await tester.pumpAndSettle();
    expect(find.text('Priya'), findsNothing);
    expect(c.read(playersProvider).map((p) => (p.position, p.name)), [
      (1, 'Rahul'),
      (2, 'Aman'),
    ]);
    expect(find.text('02'), findsOneWidget);
    expect(find.text('03'), findsNothing);
  });
}
