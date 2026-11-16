import 'dart:async';

import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../config/ad_config.dart';

/// Owns AdMob consent, SDK start-up and the post-game interstitial.
class AdService {
  AdService._();

  static final AdService instance = AdService._();

  final Completer<bool> _ready = Completer<bool>();
  bool _initStarted = false;
  bool _privacyOptionsRequired = false;

  InterstitialAd? _interstitial;
  bool _loadingInterstitial = false;
  DateTime? _lastInterstitialAt;

  /// Completes with true once ads may be requested.
  Future<bool> get whenReady => _ready.future;

  /// Whether the user must be offered a way to change ad consent (Settings).
  bool get privacyOptionsRequired => _privacyOptionsRequired;

  Future<void> initialize() async {
    if (_initStarted) return;
    _initStarted = true;

    if (!AdConfig.adsEnabled) {
      _complete(false);
      return;
    }

    try {
      await _gatherConsent();
      final canRequest = await ConsentInformation.instance.canRequestAds();
      if (!canRequest) {
        _complete(false);
        return;
      }
      await MobileAds.instance.initialize();
      _complete(true);
      _loadInterstitial();
    } catch (_) {
      _complete(false);
    }
  }

  Future<void> _gatherConsent() {
    final done = Completer<void>();

    void finish() {
      if (!done.isCompleted) done.complete();
    }

    ConsentInformation.instance.requestConsentInfoUpdate(
      ConsentRequestParameters(),
      () {
        ConsentForm.loadAndShowConsentFormIfRequired((FormError? error) async {
          try {
            final status = await ConsentInformation.instance
                .getPrivacyOptionsRequirementStatus();
            _privacyOptionsRequired =
                status == PrivacyOptionsRequirementStatus.required;
          } catch (_) {}
          finish();
        });
      },
      (FormError error) => finish(),
    );

    return done.future.timeout(const Duration(seconds: 20), onTimeout: () {});
  }

  Future<void> showPrivacyOptions() {
    final done = Completer<void>();
    ConsentForm.showPrivacyOptionsForm((FormError? error) {
      if (!done.isCompleted) done.complete();
    });
    return done.future;
  }

  void _complete(bool value) {
    if (!_ready.isCompleted) _ready.complete(value);
  }

  void _loadInterstitial() {
    if (_interstitial != null || _loadingInterstitial) return;
    _loadingInterstitial = true;
    InterstitialAd.load(
      adUnitId: AdConfig.interstitialId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _loadingInterstitial = false;
          _interstitial = ad;
        },
        onAdFailedToLoad: (error) {
          _loadingInterstitial = false;
          _interstitial = null;
        },
      ),
    );
  }

  /// Shows the interstitial after a game session, at most once per
  /// [AdConfig.interstitialCooldown]. Never called on the Player screen.
  Future<void> maybeShowInterstitial() async {
    if (!_ready.isCompleted || !await _ready.future) return;

    final last = _lastInterstitialAt;
    if (last != null &&
        DateTime.now().difference(last) < AdConfig.interstitialCooldown) {
      return;
    }

    final ad = _interstitial;
    if (ad == null) {
      _loadInterstitial();
      return;
    }

    _interstitial = null;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _loadInterstitial();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _loadInterstitial();
      },
    );
    _lastInterstitialAt = DateTime.now();
    await ad.show();
  }
}
