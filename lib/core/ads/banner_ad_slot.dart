import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ad_config.dart';

/// Anchored banner. Reserves height only once an ad can be requested, so the
/// menu does not grow a blank strip before consent. Debug/profile use sample
/// units; release uses the production unit from [AdConfig].
///
/// Never place this inside the pass-the-phone reveal. It is mounted only for
/// the home menu and the between-rounds "everyone's ready" screen, and it
/// sits outside the app's uniform scale so the platform view is not transformed.
class BannerAdSlot extends StatefulWidget {
  const BannerAdSlot({super.key});

  static const double reservedHeight = 50;

  @override
  State<BannerAdSlot> createState() => _BannerAdSlotState();
}

class _BannerAdSlotState extends State<BannerAdSlot> {
  BannerAd? _banner;
  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_banner == null) {
      _load();
    }
  }

  Future<void> _load() async {
    if (!AdConfig.adsSupported || !AdConfig.canRequestAds) return;

    final width = MediaQuery.sizeOf(context).width.truncate();
    AdSize size = AdSize.banner;
    try {
      final adaptive =
          await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(width);
      if (adaptive != null) size = adaptive;
    } catch (error) {
      debugPrint('Adaptive banner size failed: $error');
    }
    if (!mounted) return;

    final banner = BannerAd(
      adUnitId: AdConfig.bannerAdUnitId,
      size: size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (!mounted) {
            ad.dispose();
            return;
          }
          setState(() => _loaded = true);
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('Banner failed to load: $error');
          ad.dispose();
          if (mounted) setState(() => _loaded = false);
        },
      ),
    );

    _banner = banner;
    await banner.load();
  }

  @override
  void dispose() {
    _banner?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded || _banner == null) {
      if (!AdConfig.adsSupported || !AdConfig.canRequestAds) {
        return const SizedBox.shrink();
      }
      return const SizedBox(
        height: BannerAdSlot.reservedHeight,
        width: double.infinity,
      );
    }

    final height = _banner!.size.height.toDouble();
    return SafeArea(
      top: false,
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: AdWidget(ad: _banner!),
      ),
    );
  }
}
