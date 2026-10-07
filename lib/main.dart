import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'core/ads/ad_config.dart';
import 'core/ads/ads_service.dart';
import 'features/imposter/presentation/providers/providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Nunito is bundled under the SIL Open Font License, which must ship with it.
  LicenseRegistry.addLicense(() async* {
    final license = await rootBundle.loadString('assets/fonts/OFL.txt');
    yield LicenseEntryWithLineBreaks(['Nunito'], license);
  });
  await AdConfig.load();
  final prefs = await SharedPreferences.getInstance();
  final ads = AdConfig.adsSupported
      ? MobileAdsService(isTestMode: AdConfig.isTestMode)
      : FakeAdsService();
  // UMP consent runs inside initialize(), before MobileAds.initialize().
  await ads.initialize();
  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        adsServiceProvider.overrideWithValue(ads),
      ],
      child: const FindTheImposterApp(),
    ),
  );
}
