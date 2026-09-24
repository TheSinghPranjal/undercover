import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:undercover/features/imposter/domain/enums/game_phase.dart';
import 'package:undercover/features/imposter/presentation/providers/providers.dart';
import 'package:undercover/features/imposter/presentation/screens/game_config_screen.dart';
import 'package:undercover/features/imposter/presentation/widgets/secret_reveal_card.dart';

import '../helpers/test_helpers.dart';

Map<String, Object> roster(List<String> names) => {'roster.names': names};

Future<void> holdCard(WidgetTester tester) async {
  final g = await tester.startGesture(
    tester.getCenter(find.byType(SecretRevealCard)),
  );
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
  await g.up();
  await tester.pumpAndSettle();
}

Future<ProviderContainer> startRound(
  WidgetTester tester,
  List<String> names,
) async {
  final c = await pumpApp(
    tester,
    const GameConfigScreen(),
    prefs: roster(names),
  );
  await tester.tap(find.text('PASS THE PHONE'));
  await tester.pumpAndSettle();
  return c;
}

void main() {
  const names = ['Rahul', 'Priya', 'Aman', 'Neha', 'Arjun'];

  testWidgets(
    'full pass-the-phone flow to the starting player and next round',
    (tester) async {
      final c = await startRound(tester, names);
      final firstWord = c.read(gameControllerProvider).round!.word.id;

      for (var i = 0; i < names.length; i++) {
        final name = names[i];
        expect(
          find.text(i == 0 ? 'GIVE THE PHONE TO' : 'PASS THE PHONE TO'),
          findsOneWidget,
        );
        expect(find.text(name.toUpperCase()), findsOneWidget);
        expect(find.text('PLAYER ${i + 1} OF 5'), findsOneWidget);
        await tester.tap(find.text("I'M READY"));
        await tester.pumpAndSettle();

        expect(find.text('Your turn, $name 👀'), findsOneWidget);
        expect(find.text('SECRET CARD'), findsOneWidget);
        expect(find.text('PASS TO NEXT PLAYER'), findsNothing);
        await holdCard(tester);
        expect(find.text('Keep this secret 🤫'), findsOneWidget);

        final isImposter = c.read(currentAssignmentProvider)!.isImposter;
        expect(
          find.text('THE IMPOSTER'),
          isImposter ? findsOneWidget : findsNothing,
        );
        expect(
          find.text('YOUR SECRET WORD'),
          isImposter ? findsNothing : findsOneWidget,
        );
        if (i < 2) {
          expect(
            isImposter,
            isFalse,
            reason: 'seats 1 and 2 are never imposters',
          );
        }

        if (i < names.length - 1) {
          expect(find.text('START GAME'), findsNothing);
          await tester.tap(find.text('PASS TO NEXT PLAYER'));
        } else {
          expect(find.text('PASS TO NEXT PLAYER'), findsNothing);
          expect(find.text('Everyone has seen their role.'), findsOneWidget);
          await tester.tap(find.text('START GAME'));
        }
        await tester.pumpAndSettle();
        // Previous secret is gone.
        expect(find.text('YOUR SECRET WORD'), findsNothing);
        expect(find.text('THE IMPOSTER'), findsNothing);
      }

      final starter = c.read(gameControllerProvider).round!.startingPlayer;
      expect(find.text('Let the chaos begin!'), findsOneWidget);
      expect(find.text('${starter.name} starts!'), findsOneWidget);

      await tester.tap(find.text('AGAIN! 🔥'));
      await tester.pumpAndSettle();
      expect(find.text('GIVE THE PHONE TO'), findsOneWidget);
      expect(find.text('RAHUL'), findsOneWidget);
      expect(c.read(gameControllerProvider).round!.word.id, isNot(firstWord));
      expect(c.read(playersProvider).map((p) => p.name), names);
    },
  );

  testWidgets('backgrounding hides a revealed card', (tester) async {
    final c = await startRound(tester, names);
    await tester.tap(find.text("I'M READY"));
    await tester.pumpAndSettle();
    await holdCard(tester);
    expect(find.text('YOUR SECRET WORD'), findsOneWidget);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pumpAndSettle();
    expect(c.read(gamePhaseProvider), GamePhase.privacyHidden);
    expect(find.text('YOUR SECRET WORD'), findsNothing);
    expect(find.text('SCREEN HIDDEN FOR PRIVACY'), findsOneWidget);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(find.text('YOUR SECRET WORD'), findsNothing);
    await tester.tap(find.text("I'M READY"));
    await tester.pumpAndSettle();
    expect(find.text('SECRET CARD'), findsOneWidget, reason: 'must hold again');
  });

  testWidgets('back during reveal asks twice before discarding', (
    tester,
  ) async {
    final c = await startRound(tester, names);
    final round = c.read(gameControllerProvider).round;

    await tester.tap(find.byTooltip('Leave round'));
    await tester.pumpAndSettle();
    expect(find.text('Leave this round?'), findsOneWidget);
    expect(
      find.text('Your secret card has already been assigned.'),
      findsOneWidget,
    );
    await tester.tap(find.text('KEEP PLAYING'));
    await tester.pumpAndSettle();
    expect(
      c.read(gameControllerProvider).round,
      same(round),
      reason: 'not regenerated',
    );

    await tester.tap(find.byTooltip('Leave round'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('EXIT ROUND'));
    await tester.pumpAndSettle();
    expect(find.text('Discard this round?'), findsOneWidget);
    await tester.tap(find.text('DISCARD'));
    await tester.pumpAndSettle();

    expect(find.byType(GameConfigScreen), findsOneWidget);
    expect(c.read(gameControllerProvider).round, isNull);
  });

  testWidgets('hint appears for imposters only when enabled', (tester) async {
    final c = await pumpApp(
      tester,
      const GameConfigScreen(),
      prefs: {...roster(names), 'settings.showHint': true},
    );
    await tester.tap(find.text('PASS THE PHONE'));
    await tester.pumpAndSettle();
    final round = c.read(gameControllerProvider).round!;
    final imposterSeat = round.players.indexWhere(
      (p) => round.imposterIds.contains(p.id),
    );
    for (var i = 0; i <= imposterSeat; i++) {
      await tester.tap(find.text("I'M READY"));
      await tester.pumpAndSettle();
      await holdCard(tester);
      if (i < imposterSeat) {
        expect(find.text('HINT'), findsNothing);
        await tester.tap(find.text('PASS TO NEXT PLAYER'));
        await tester.pumpAndSettle();
      }
    }
    expect(find.text('THE IMPOSTER'), findsOneWidget);
    expect(find.text('HINT'), findsOneWidget);
    expect(find.text(round.word.hint.toUpperCase()), findsOneWidget);
    expect(find.text(round.secretWord.toUpperCase()), findsNothing);
  });
}
