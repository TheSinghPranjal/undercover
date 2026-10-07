// Store-screenshot harness. Renders the real app (not a mock) in the Flutter
// test environment at each target logical size and device pixel ratio, drives
// the actual buttons, and writes PNGs.
//
//   flutter test tool/capture_store_screenshots.dart
//   flutter test tool/capture_store_screenshots.dart --dart-define=SET=phone
//
// Outputs land in /opt/cursor/artifacts/store_screenshots/<set>/.

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:undercover/app/app.dart';
import 'package:undercover/features/imposter/presentation/providers/providers.dart';
import 'package:undercover/features/imposter/presentation/widgets/secret_reveal_card.dart';

const _outRoot = '/opt/cursor/artifacts/store_screenshots';
const _onlySet = String.fromEnvironment('SET');

const _names = ['Aarav', 'Priya', 'Rohan', 'Meera', 'Kabir'];

class _ShotSet {
  const _ShotSet(this.name, this.physical, this.dpr);
  final String name;
  final Size physical;
  final double dpr;
  Size get logical => physical / dpr;
}

const _sets = <_ShotSet>[
  _ShotSet('phone', Size(1080, 1920), 3),
  // Exact 9:16, close to 1200x2133. Logical ~600-wide tablet.
  _ShotSet('tablet7', Size(1206, 2144), 2),
  // Exact 1440x2560. Logical 720x1280 is a large tablet.
  _ShotSet('tablet10', Size(1440, 2560), 2),
  // Landscape 1920×1080 scales the home header with the window width, which
  // pushes START GAME / HOW TO PLAY / SETTINGS below the fold. Portrait
  // 1440×2560 (same logical size as the 10" tablet) keeps every screen on
  // one page.
  _ShotSet('desktop', Size(1440, 2560), 2),
];

void main() {
  final sets = _onlySet.isEmpty
      ? _sets
      : _sets.where((s) => s.name == _onlySet).toList();
  if (sets.isEmpty) {
    throw StateError('Unknown SET=$_onlySet');
  }

  for (final shotSet in sets) {
    testWidgets('capture ${shotSet.name}', (tester) async {
      await _captureSet(tester, shotSet);
    }, timeout: const Timeout(Duration(minutes: 4)));
  }
}

Future<void> _captureSet(WidgetTester tester, _ShotSet shotSet) async {
  tester.view.physicalSize = shotSet.physical;
  tester.view.devicePixelRatio = shotSet.dpr;
  addTearDown(tester.view.reset);

  // ignore: invalid_use_of_visible_for_testing_member
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const FindTheImposterApp(),
    ),
  );

  final context = tester.element(find.byType(FindTheImposterApp));
  await tester.runAsync(() async {
    await precacheImage(
      const AssetImage('assets/images/home_background.webp'),
      context,
    );
    await precacheImage(
      const AssetImage('assets/images/round_ready_background.webp'),
      context,
    );
  });

  final dir = Directory('$_outRoot/${shotSet.name}');
  if (!dir.existsSync()) dir.createSync(recursive: true);

  Future<void> shot(String file) =>
      _saveShot(tester, '${dir.path}/$file', shotSet);

  // Splash waits 1.3s for the word pack, then fades into home.
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 1500));
  await tester.pump(const Duration(milliseconds: 600));
  if (find.text('START GAME').evaluate().isEmpty) {
    debugDumpApp();
  }
  expect(find.text('START GAME'), findsOneWidget);
  await shot('01_home.png');

  await tester.tap(find.text('HOW TO PLAY'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
  expect(find.text('1. ADD PLAYERS'), findsOneWidget);
  await shot('08_how_to_play.png');

  await tester.tap(find.byTooltip('Back'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  expect(find.text('START GAME'), findsOneWidget);

  await tester.tap(find.text('START GAME'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));

  for (final name in _names) {
    await tester.enterText(find.byType(TextField), name);
    await tester.pump();
    await tester.tap(find.text('ADD'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pump(const Duration(milliseconds: 300));
  expect(find.text('Aarav'), findsOneWidget);
  expect(find.text('Kabir'), findsOneWidget);
  await shot('02_player_setup.png');

  await tester.tap(find.text('CONTINUE'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
  expect(find.text('PASS THE PHONE'), findsOneWidget);
  await shot('03_game_config.png');

  // The hint toggle sits below the fold on shorter phones.
  final hint = find.text('Give a hint');
  await tester.scrollUntilVisible(
    hint,
    150,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pump(const Duration(milliseconds: 200));
  await tester.tap(hint);
  await tester.pump(const Duration(milliseconds: 300));

  await tester.ensureVisible(find.text('PASS THE PHONE'));
  await tester.pump(const Duration(milliseconds: 200));
  await tester.tap(find.text('PASS THE PHONE'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
  expect(find.text("I'M READY"), findsOneWidget);
  expect(find.text('AARAV'), findsOneWidget);
  await shot('04_pass_phone.png');

  final container = ProviderScope.containerOf(
    tester.element(find.byType(FindTheImposterApp)),
  );
  final round = container.read(gameControllerProvider).round!;
  final imposterNames = [
    for (final p in round.players)
      if (round.imposterIds.contains(p.id)) p.name,
  ];
  // Printed so the capture log can describe the dealt round accurately.
  // ignore: avoid_print
  print(
    '${shotSet.name}: word="${round.secretWord}" hint="${round.word.hint}" '
    'category=${round.word.category} imposters=$imposterNames '
    'starts=${round.startingPlayer.name} logical=${shotSet.logical} '
    'physical=${shotSet.physical} dpr=${shotSet.dpr}',
  );

  var savedCivilian = false;
  var savedImposter = false;
  for (var i = 0; i < _names.length; i++) {
    if (i > 0) {
      expect(find.text(_names[i].toUpperCase()), findsOneWidget);
    }
    await tester.tap(find.text("I'M READY"));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(SecretRevealCard)),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1000));
    await gesture.up();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));

    final isImposter = find.text('THE IMPOSTER').evaluate().isNotEmpty;
    if (!isImposter) {
      expect(find.text('YOUR SECRET WORD'), findsOneWidget);
    }
    if (!savedCivilian && !isImposter) {
      await shot('05_reveal_word.png');
      savedCivilian = true;
    }
    if (!savedImposter && isImposter) {
      await shot('06_reveal_imposter.png');
      savedImposter = true;
    }

    final last = i == _names.length - 1;
    await tester.tap(find.text(last ? 'START GAME' : 'PASS TO NEXT PLAYER'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 900));
  }

  expect(savedCivilian, isTrue, reason: 'never revealed a civilian card');
  expect(savedImposter, isTrue, reason: 'never revealed the imposter card');
  expect(find.textContaining('starts'), findsWidgets);
  await tester.pump(const Duration(milliseconds: 2000));
  await shot('07_round_ready.png');
}

Future<void> _saveShot(
  WidgetTester tester,
  String path,
  _ShotSet shotSet,
) async {
  await tester.pump();
  final element = tester.element(find.byType(FindTheImposterApp));
  final image = await tester.runAsync(() async {
    RenderObject renderObject = element.renderObject!;
    while (renderObject.parent != null) {
      renderObject = renderObject.parent!;
    }
    expect(renderObject.debugNeedsPaint, isFalse);
    final layer = renderObject.debugLayer! as OffsetLayer;
    // RenderView.paintBounds is already in physical pixels (logical size ×
    // device pixel ratio), so pixelRatio 1 captures that framebuffer 1:1.
    return layer.toImage(renderObject.paintBounds);
  });
  expect(image, isNotNull);
  final width = image!.width;
  final height = image.height;
  expect(width, shotSet.physical.width.round(), reason: 'width of $path');
  expect(height, shotSet.physical.height.round(), reason: 'height of $path');
  final bytes = await tester.runAsync(
    () => image.toByteData(format: ui.ImageByteFormat.png),
  );
  image.dispose();
  final data = bytes!.buffer.asUint8List();
  File(path).writeAsBytesSync(data);
  expect(data.lengthInBytes, lessThan(8 * 1024 * 1024), reason: path);
  // ignore: avoid_print
  print('wrote $path (${width}x$height, ${data.lengthInBytes} bytes)');
}
