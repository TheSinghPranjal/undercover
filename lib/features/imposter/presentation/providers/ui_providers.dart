import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers.dart';

/// Whether decorative animations should run: the in-app setting and the
/// system "reduce motion" preference must both allow it.
bool animationsOn(BuildContext context, WidgetRef ref) =>
    ref.watch(gameSettingsProvider.select((s) => s.animationsEnabled)) &&
    !MediaQuery.of(context).disableAnimations;
