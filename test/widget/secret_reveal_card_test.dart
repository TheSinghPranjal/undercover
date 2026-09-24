import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:undercover/app/theme/app_theme.dart';
import 'package:undercover/features/imposter/domain/entities/player_assignment.dart';
import 'package:undercover/features/imposter/presentation/widgets/secret_reveal_card.dart';

import '../helpers/test_helpers.dart';

/// Hosts the card and plays the parent's role: flips it when revealed.
class Host extends StatefulWidget {
  const Host({super.key, required this.assignment, this.tapToReveal = false});

  final PlayerAssignment assignment;
  final bool tapToReveal;

  @override
  State<Host> createState() => HostState();
}

class HostState extends State<Host> {
  bool revealed = false;
  int reveals = 0;
  int hidden = 0;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      SizedBox(
        width: 300,
        height: 420,
        child: SecretRevealCard(
          playerName: 'Aman',
          assignment: revealed ? widget.assignment : null,
          isRevealed: revealed,
          tapToReveal: widget.tapToReveal,
          onRevealed: () => setState(() {
            reveals++;
            revealed = true;
          }),
          onHidden: () => hidden++,
        ),
      ),
      TextButton(
        onPressed: () => setState(() => revealed = false),
        child: const Text('hide'),
      ),
    ],
  );
}

Future<HostState> pumpCard(
  WidgetTester tester,
  PlayerAssignment a, {
  bool tapToReveal = false,
}) async {
  final overrides = await testOverrides();
  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: Host(assignment: a, tapToReveal: tapToReveal),
        ),
      ),
    ),
  );
  return tester.state<HostState>(find.byType(Host));
}

void main() {
  const civilian = PlayerAssignment.civilian(playerId: 'p1', word: 'Water');
  const imposter = PlayerAssignment.imposter(playerId: 'p3', hint: 'Liquid');
  const imposterNoHint = PlayerAssignment.imposter(playerId: 'p3');

  testWidgets('starts face-down with hold instructions', (tester) async {
    await pumpCard(tester, civilian);
    expect(find.text('SECRET CARD'), findsOneWidget);
    expect(find.text('Press & hold to reveal'), findsOneWidget);
    expect(find.text('WATER'), findsNothing);
  });

  testWidgets('a quick tap does not reveal', (tester) async {
    final host = await pumpCard(tester, civilian);
    await tester.tap(find.byType(SecretRevealCard));
    await tester.pumpAndSettle();
    expect(host.reveals, 0);
    expect(find.text('WATER'), findsNothing);
  });

  testWidgets('releasing early does not reveal', (tester) async {
    final host = await pumpCard(tester, civilian);
    final g = await tester.startGesture(
      tester.getCenter(find.byType(SecretRevealCard)),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await g.up();
    await tester.pumpAndSettle();
    expect(host.reveals, 0);
  });

  testWidgets('press & hold reveals and flips to the word', (tester) async {
    final host = await pumpCard(tester, civilian);
    final g = await tester.startGesture(
      tester.getCenter(find.byType(SecretRevealCard)),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 500));
    await g.up();
    expect(host.reveals, 1);
    await tester.pumpAndSettle();
    expect(find.text('YOUR SECRET WORD'), findsOneWidget);
    expect(find.text('WATER'), findsOneWidget);
    expect(find.text('SECRET CARD'), findsNothing);
  });

  testWidgets('flips back and reports when face-down', (tester) async {
    final host = await pumpCard(tester, civilian);
    final g = await tester.startGesture(
      tester.getCenter(find.byType(SecretRevealCard)),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await g.up();
    await tester.pumpAndSettle();
    await tester.tap(find.text('hide'));
    await tester.pumpAndSettle();
    expect(host.hidden, 1);
    expect(find.text('WATER'), findsNothing);
    expect(find.text('SECRET CARD'), findsOneWidget);
  });

  testWidgets('imposter sees the role and hint, never a word', (tester) async {
    await pumpCard(tester, imposter);
    final g = await tester.startGesture(
      tester.getCenter(find.byType(SecretRevealCard)),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await g.up();
    await tester.pumpAndSettle();
    expect(find.text('THE IMPOSTER'), findsOneWidget);
    expect(find.text('HINT'), findsOneWidget);
    expect(find.text('LIQUID'), findsOneWidget);
    expect(find.text('WATER'), findsNothing);
  });

  testWidgets('imposter without hint sees no hint box', (tester) async {
    await pumpCard(tester, imposterNoHint);
    final g = await tester.startGesture(
      tester.getCenter(find.byType(SecretRevealCard)),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await g.up();
    await tester.pumpAndSettle();
    expect(find.text('THE IMPOSTER'), findsOneWidget);
    expect(find.text('HINT'), findsNothing);
  });

  testWidgets('tap-to-reveal accessibility fallback', (tester) async {
    final host = await pumpCard(tester, civilian, tapToReveal: true);
    expect(find.text('Tap to reveal'), findsOneWidget);
    await tester.tap(find.byType(SecretRevealCard));
    await tester.pumpAndSettle();
    expect(host.reveals, 1);
    expect(find.text('WATER'), findsOneWidget);
  });
}
