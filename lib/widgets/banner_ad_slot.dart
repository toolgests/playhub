import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../config/ad_config.dart';
import '../services/ad_service.dart';
import '../services/realtime_ad_service.dart';

/// Anchored adaptive banner. Takes no space until an ad has loaded, so the
/// layout never jumps around an empty box.
class BannerAdSlot extends StatefulWidget {
  const BannerAdSlot({super.key, required this.adUnitId});

  final String adUnitId;

  @override
  State<BannerAdSlot> createState() => _BannerAdSlotState();
}

class _BannerAdSlotState extends State<BannerAdSlot> {
  BannerAd? _ad;
  bool _loaded = false;
  bool _requested = false;

  @override
  void initState() {
    super.initState();
    RealtimeAdService.instance.adsEnabledNotifier
        .addListener(_onAdsEnabledChanged);
  }

  void _onAdsEnabledChanged() {
    if (!AdConfig.adsEnabled) {
      _ad?.dispose();
      if (mounted) {
        setState(() {
          _ad = null;
          _loaded = false;
        });
      }
    } else if (_ad == null && mounted) {
      _requested = false;
      _load();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_requested) {
      _requested = true;
      _load();
    }
  }

  Future<void> _load() async {
    if (!AdConfig.adsEnabled) return;
    final canShow = await AdService.instance.whenReady;
    if (!canShow || !mounted) return;

    final width = MediaQuery.sizeOf(context).width.truncate();
    final size =
        await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(width);
    if (size == null || !mounted) return;

    final ad = BannerAd(
      adUnitId: widget.adUnitId,
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
          ad.dispose();
          if (mounted) {
            setState(() {
              _ad = null;
              _loaded = false;
            });
          }
        },
      ),
    );
    _ad = ad;
    await ad.load();
  }

  @override
  void dispose() {
    RealtimeAdService.instance.adsEnabledNotifier
        .removeListener(_onAdsEnabledChanged);
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ad = _ad;
    if (!_loaded || ad == null) return const SizedBox.shrink();
    return Center(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          width: ad.size.width.toDouble(),
          height: ad.size.height.toDouble(),
          child: AdWidget(ad: ad),
        ),
      ),
    );
  }
}
