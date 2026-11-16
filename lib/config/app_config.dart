/// App-wide constants.
abstract final class AppConfig {
  static const String appName = 'PlayHub';
  static const String tagline = 'Play instantly. No downloads.';

  static const String catalogAsset = 'assets/games.json';

  static const String apiBaseUrl = 'https://playhubbackend-hfbd-gilt.vercel.app';
  static const String liveGamesApiUrl = '$apiBaseUrl/';
  static const String notificationsApiUrl = '$apiBaseUrl/notifications';

  static const int pageSize = 30;
  static const int recentLimit = 20;
  static const int featuredCount = 8;
  static const int homeGenreChips = 12;
  static const int similarGamesCount = 12;

  static const String privacyPolicyUrl = 'https://example.com/privacy-policy';
  static const int minimumAge = 13;
}
