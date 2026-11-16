import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Firebase Remote Config Service — Exclusively for App Update Popup.
class RemoteConfigService {
  RemoteConfigService._();
  static final RemoteConfigService instance = RemoteConfigService._();

  FirebaseRemoteConfig? _remoteConfig;
  bool _initialized = false;

  /// Remote Config Keys for App Update
  static const String keyLatestVersion = 'latest_version';
  static const String keyMinVersion = 'min_supported_version';
  static const String keyForceUpdate = 'force_update';
  static const String keyUpdateUrl = 'update_url';
  static const String keyUpdateTitle = 'update_title';
  static const String keyUpdateMessage = 'update_message';

  static Map<String, dynamic> get _defaults => <String, dynamic>{
        keyLatestVersion: '1.0.0',
        keyMinVersion: '1.0.0',
        keyForceUpdate: false,
        keyUpdateUrl:
            'https://play.google.com/store/apps/details?id=com.playhub.app',
        keyUpdateTitle: 'New Update Available! 🚀',
        keyUpdateMessage:
            'A newer version of PlayHub is available with exciting new games and performance improvements. Please update now for the best experience!',
      };

  Future<void> initialize() async {
    if (_initialized) return;
    try {
      _remoteConfig = FirebaseRemoteConfig.instance;

      await _remoteConfig!.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 15),
          minimumFetchInterval:
              kDebugMode ? Duration.zero : const Duration(hours: 1),
        ),
      );

      await _remoteConfig!.setDefaults(_defaults);

      final updated = await _remoteConfig!.fetchAndActivate();
      _initialized = true;

      debugPrint(
        '🔥 [Remote Config] Initialized for App Update. Updated from server: $updated',
      );
      debugPrint('🔥 [Remote Config] Latest Version: $latestVersion');
      debugPrint('🔥 [Remote Config] Min Supported Version: $minSupportedVersion');
      debugPrint('🔥 [Remote Config] Force Update: $isForceUpdate');
      debugPrint('🔥 [Remote Config] Update URL: $updateUrl');

      // Listen for real-time config changes in Firebase Console
      _remoteConfig!.onConfigUpdated.listen((event) async {
        debugPrint('🔥 [Remote Config] Config updated in Firebase Console!');
        await _remoteConfig!.activate();
      });
    } catch (e, st) {
      debugPrint('⚠️ [Remote Config] Error initializing Remote Config: $e\n$st');
    }
  }

  String get latestVersion =>
      _remoteConfig?.getString(keyLatestVersion).isNotEmpty == true
          ? _remoteConfig!.getString(keyLatestVersion)
          : '1.0.0';

  String get minSupportedVersion =>
      _remoteConfig?.getString(keyMinVersion).isNotEmpty == true
          ? _remoteConfig!.getString(keyMinVersion)
          : '1.0.0';

  bool get isForceUpdate =>
      _remoteConfig?.getBool(keyForceUpdate) ?? false;

  String get updateUrl =>
      _remoteConfig?.getString(keyUpdateUrl).isNotEmpty == true
          ? _remoteConfig!.getString(keyUpdateUrl)
          : 'https://play.google.com/store/apps/details?id=com.playhub.app';

  String get updateTitle =>
      _remoteConfig?.getString(keyUpdateTitle).isNotEmpty == true
          ? _remoteConfig!.getString(keyUpdateTitle)
          : 'New Update Available! 🚀';

  String get updateMessage =>
      _remoteConfig?.getString(keyUpdateMessage).isNotEmpty == true
          ? _remoteConfig!.getString(keyUpdateMessage)
          : 'A newer version of PlayHub is available with exciting new games and performance improvements. Please update now!';

  /// Evaluates whether an update is available or required for the given [currentVersion].
  AppUpdateInfo checkUpdate(String currentVersion) {
    final cleanCurrent = _cleanVersion(currentVersion);
    final cleanLatest = _cleanVersion(latestVersion);
    final cleanMin = _cleanVersion(minSupportedVersion);

    final isNewerAvailable = _isVersionOlder(cleanCurrent, cleanLatest);
    final isBelowMin = _isVersionOlder(cleanCurrent, cleanMin);
    final force = isForceUpdate || isBelowMin;

    return AppUpdateInfo(
      hasUpdate: isNewerAvailable || isBelowMin,
      isForceUpdate: force,
      latestVersion: latestVersion,
      updateUrl: updateUrl,
      title: updateTitle,
      message: updateMessage,
    );
  }

  /// Convenience method that fetches the device package version and checks.
  Future<AppUpdateInfo> checkDeviceUpdate() async {
    try {
      final info = await PackageInfo.fromPlatform();
      return checkUpdate(info.version);
    } catch (_) {
      return checkUpdate('1.0.0');
    }
  }

  static String _cleanVersion(String v) {
    return v.split('+').first.trim();
  }

  /// Returns true if [current] is strictly older than [target].
  static bool _isVersionOlder(String current, String target) {
    try {
      final currentParts =
          current.split('.').map((p) => int.tryParse(p) ?? 0).toList();
      final targetParts =
          target.split('.').map((p) => int.tryParse(p) ?? 0).toList();

      while (currentParts.length < 3) currentParts.add(0);
      while (targetParts.length < 3) targetParts.add(0);

      for (var i = 0; i < 3; i++) {
        if (currentParts[i] < targetParts[i]) return true;
        if (currentParts[i] > targetParts[i]) return false;
      }
      return false;
    } catch (_) {
      return false;
    }
  }
}

class AppUpdateInfo {
  const AppUpdateInfo({
    required this.hasUpdate,
    required this.isForceUpdate,
    required this.latestVersion,
    required this.updateUrl,
    required this.title,
    required this.message,
  });

  final bool hasUpdate;
  final bool isForceUpdate;
  final String latestVersion;
  final String updateUrl;
  final String title;
  final String message;
}
