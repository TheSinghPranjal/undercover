import 'package:flutter/services.dart';

/// Thin wrapper so haptics can be switched off in settings and faked in tests.
class HapticsService {
  const HapticsService({required this.enabled});

  final bool enabled;

  void light() => _run(HapticFeedback.lightImpact);
  void selection() => _run(HapticFeedback.selectionClick);
  void medium() => _run(HapticFeedback.mediumImpact);
  void success() => _run(HapticFeedback.heavyImpact);

  void _run(Future<void> Function() effect) {
    if (enabled) effect();
  }
}
