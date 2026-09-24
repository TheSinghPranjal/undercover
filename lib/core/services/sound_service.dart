import 'package:flutter/services.dart';

/// Subtle UI sounds. Uses the platform click so no audio assets are bundled.
///
/// Deliberately never called from the secret reveal: a sound there could tell
/// the rest of the table something.
class SoundService {
  const SoundService({required this.enabled});

  final bool enabled;

  void tap() {
    if (enabled) SystemSound.play(SystemSoundType.click);
  }
}
