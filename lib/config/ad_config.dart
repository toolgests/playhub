/// All AdMob identifiers live here.
/// Defaults are Google's official test IDs; they are dynamically controlled
/// and updated at runtime via Firebase Realtime Database.
abstract final class AdConfig {
  // --- Default constants (fallbacks) ---
  static const bool defaultAdsEnabled = true;
  static const String defaultAndroidAppId =
      'ca-app-pub-4489076028672992~7576969541';
  static const String defaultHomeBannerId =
      'ca-app-pub-3940256099942544/9214589741';
  static const String defaultDetailBannerId =
      'ca-app-pub-3940256099942544/9214589741';
  static const String defaultInterstitialId =
      'ca-app-pub-3940256099942544/1033173712';
  static const Duration defaultInterstitialCooldown = Duration(minutes: 3);

  // --- Dynamic properties (controlled live from Firebase Realtime Database) ---
  static bool adsEnabled = defaultAdsEnabled;
  static String androidAppId = defaultAndroidAppId;
  static String homeBannerId = defaultHomeBannerId;
  static String detailBannerId = defaultDetailBannerId;
  static String interstitialId = defaultInterstitialId;
  static Duration interstitialCooldown = defaultInterstitialCooldown;

  /// Resets configuration back to defaults
  static void resetToDefaults() {
    adsEnabled = defaultAdsEnabled;
    androidAppId = defaultAndroidAppId;
    homeBannerId = defaultHomeBannerId;
    detailBannerId = defaultDetailBannerId;
    interstitialId = defaultInterstitialId;
    interstitialCooldown = defaultInterstitialCooldown;
  }
}
