import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:undercover/app/app.dart';
import 'package:undercover/features/imposter/data/datasources/word_asset_datasource.dart';
import 'package:undercover/features/imposter/data/repositories/word_repository_impl.dart';
import 'package:undercover/features/imposter/domain/entities/player.dart';
import 'package:undercover/features/imposter/domain/entities/word_entry.dart';
import 'package:undercover/features/imposter/presentation/providers/providers.dart';

List<WordEntry>? _pack;

/// The real bundled word pack, read straight from disk.
List<WordEntry> realWordPack() => _pack ??= WordAssetDataSource.parse(
  File('assets/data/imposter_words.json').readAsStringSync(),
);

List<Player> makePlayers(int n) => [
  for (var i = 1; i <= n; i++)
    Player(id: 'p$i', name: 'Player $i', position: i),
];

Future<List<Override>> testOverrides({
  Map<String, Object> prefs = const {},
  int seed = 42,
  List<Override> extra = const [],
}) async {
  SharedPreferences.setMockInitialValues(prefs);
  final sp = await SharedPreferences.getInstance();
  return [
    sharedPreferencesProvider.overrideWithValue(sp),
    randomProvider.overrideWithValue(Random(seed)),
    wordRepositoryProvider.overrideWith(
      (ref) async =>
          InMemoryWordRepository(realWordPack(), random: Random(seed)),
    ),
    ...extra,
  ];
}

Future<ProviderContainer> makeContainer({
  Map<String, Object> prefs = const {},
  int seed = 42,
  List<Override> extra = const [],
}) async => ProviderContainer.test(
  overrides: await testOverrides(prefs: prefs, seed: seed, extra: extra),
);

/// Pumps the app starting at [home] with animations disabled so
/// pumpAndSettle doesn't wait on decorative loops.
Future<ProviderContainer> pumpApp(
  WidgetTester tester,
  Widget home, {
  Map<String, Object> prefs = const {},
  int seed = 42,
  List<Override> extra = const [],
}) async {
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      const FakeAccessibilityFeatures(disableAnimations: true);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
  tester.view.physicalSize = const Size(1080, 2340);
  tester.view.devicePixelRatio = 2.75;
  addTearDown(tester.view.reset);

  final overrides = await testOverrides(prefs: prefs, seed: seed, extra: extra);
  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides,
      child: FindTheImposterApp(home: home),
    ),
  );
  await tester.pumpAndSettle();
  return ProviderScope.containerOf(
    tester.element(find.byType(FindTheImposterApp)),
  );
}
