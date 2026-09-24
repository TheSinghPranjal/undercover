import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Blocks screenshots and blanks the recent-apps preview while secrets are
/// on screen (Android FLAG_SECURE). A no-op on platforms without the channel.
class PrivacyService {
  const PrivacyService();

  static const _channel = MethodChannel('find_the_imposter/privacy');

  Future<void> setSecure(bool secure) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    try {
      await _channel.invokeMethod<void>('setSecure', secure);
    } on MissingPluginException {
      // Not available (e.g. tests) – lifecycle hiding still protects secrets.
    } on PlatformException {
      // Ignore: failing to toggle the flag must never break the game.
    }
  }
}
