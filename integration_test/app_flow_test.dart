import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:undercover/app/app.dart';
import 'package:undercover/features/imposter/presentation/providers/providers.dart';
import 'package:undercover/features/imposter/presentation/widgets/secret_reveal_card.dart';

/// Complete flow with the real bundled word pack:
/// add players → configure → reveal every card → start → starting player →
/// next round.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('complete game flow', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: const FindTheImposterApp(),
      ),
    );

    // Splash → home.
    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('START GAME'), findsOneWidget);
    await tester.tap(find.text('START GAME'));
    await tester.pumpAndSettle();

    // Add players.
    const names = ['Rahul', 'Priya', 'Aman', 'Neha'];
    for (final name in names) {
      await tester.enterText(find.byType(TextField), name);
      await tester.tap(find.text('ADD'));
      await tester.pumpAndSettle();
    }
    await tester.tap(find.text('CONTINUE'));
    await tester.pumpAndSettle();

    // Configure: medium, hints on.
    await tester.tap(find.bySemanticsLabel('Medium difficulty'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Show hint to imposter'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Show hint to imposter'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('PASS THE PHONE'));
    // The pass-phone screen has a looping bounce, so pump instead of settle.
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));

    final container = ProviderScope.containerOf(
      tester.element(find.byType(FindTheImposterApp)),
    );
    final firstWord = container.read(gameControllerProvider).round!.word.id;

    Future<void> playRound() async {
      for (var i = 0; i < names.length; i++) {
        expect(find.text(names[i].toUpperCase()), findsOneWidget);
        await tester.tap(find.text("I'M READY"));
        await tester.pumpAndSettle();

        final g = await tester.startGesture(
          tester.getCenter(find.byType(SecretRevealCard)),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 1000));
        await g.up();
        await tester.pumpAndSettle();

        final last = i == names.length - 1;
        expect(
          find.text(last ? 'START GAME' : 'PASS TO NEXT PLAYER'),
          findsOneWidget,
        );
        await tester.tap(
          find.text(last ? 'START GAME' : 'PASS TO NEXT PLAYER'),
        );
        await tester.pump(const Duration(seconds: 1));
        await tester.pump(const Duration(seconds: 1));
      }
    }

    await playRound();
    final starter = container
        .read(gameControllerProvider)
        .round!
        .startingPlayer;
    expect(find.text('${starter.name} starts!'), findsOneWidget);

    // Next round: same players, new word.
    await tester.tap(find.text('AGAIN! 🔥'));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    expect(
      container.read(gameControllerProvider).round!.word.id,
      isNot(firstWord),
    );
    await playRound();
    expect(find.textContaining('starts!'), findsOneWidget);
  });
}
