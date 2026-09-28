import 'package:flutter_test/flutter_test.dart';
import 'package:undercover/features/imposter/presentation/screens/home_screen.dart';
import 'package:undercover/features/imposter/presentation/screens/player_setup_screen.dart';
import 'package:undercover/features/imposter/presentation/screens/splash_screen.dart';

import '../helpers/test_helpers.dart';

void main() {
  testWidgets('splash loads the word pack then shows home', (tester) async {
    await pumpApp(
      tester,
      const SplashScreen(minimumDuration: Duration(milliseconds: 100)),
    );
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(
      find.text("Everyone knows the word.\nOne of you doesn't."),
      findsOneWidget,
    );
  });

  testWidgets('home navigates to player setup and how to play', (tester) async {
    await pumpApp(tester, const HomeScreen());
    await tester.tap(find.text('HOW TO PLAY'));
    await tester.pumpAndSettle();
    // Every step is on a single screen.
    expect(find.text('1. ADD PLAYERS'), findsOneWidget);
    expect(find.text('5. NEW ROUND'), findsOneWidget);
    await tester.tap(find.text('GOT IT!'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('START GAME'));
    await tester.pumpAndSettle();
    expect(find.byType(PlayerSetupScreen), findsOneWidget);
  });
}
