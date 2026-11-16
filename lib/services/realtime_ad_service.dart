import 'dart:async';
import 'dart:convert';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/ad_config.dart';

/// Service to sync AdMob settings dynamically from Firebase Realtime Database.
class RealtimeAdService {
  RealtimeAdService._();
  static final RealtimeAdService instance = RealtimeAdService._();

  static const String _cacheKey = 'cached_realtime_ad_config_v1';
  final ValueNotifier<bool> adsEnabledNotifier =
      ValueNotifier<bool>(AdConfig.defaultAdsEnabled);

  StreamSubscription<DatabaseEvent>? _subscription;
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    // 1. Load cached values first for instant offline startup
    await _loadFromCache();

    // 2. Connect to Firebase Realtime Database and listen for live updates
    try {
      final database = FirebaseDatabase.instance;
      // Enable disk persistence on mobile platforms
      if (!kIsWeb) {
        try {
          database.setPersistenceEnabled(true);
        } catch (_) {}
      }

      // Check both 'ad_config' or 'ads' root node
      final ref = database.ref('ad_config');

      // Fetch once initially
      final snapshot = await ref.get().timeout(const Duration(seconds: 10));
      if (snapshot.exists && snapshot.value != null) {
        _applyData(snapshot.value);
      } else {
        // Fallback to check 'ads' path if 'ad_config' is empty
        final altSnapshot =
            await database.ref('ads').get().timeout(const Duration(seconds: 5));
        if (altSnapshot.exists && altSnapshot.value != null) {
          _applyData(altSnapshot.value);
        }
      }

      // Listen for continuous live updates from Firebase Realtime Database
      _subscription = ref.onValue.listen((event) {
        if (event.snapshot.exists && event.snapshot.value != null) {
          debugPrint('🔥 [Realtime Ads] Realtime update event received from Firebase!');
          _applyData(event.snapshot.value);
        }
      }, onError: (Object e) {
        debugPrint('⚠️ [Realtime Ads] Stream error: $e');
      });
    } catch (e, st) {
      debugPrint('⚠️ [Realtime Ads] Failed to connect to Realtime Database: $e\n$st');
    }
  }

  void _applyData(dynamic rawData) {
    if (rawData == null) return;
    Map<String, dynamic> map = {};

    if (rawData is Map) {
      map = rawData.map((k, v) => MapEntry(k.toString(), v));
    } else {
      return;
    }

    // ads_enabled / adsEnabled
    final rawEnabled = map['ads_enabled'] ?? map['adsEnabled'];
    if (rawEnabled != null) {
      if (rawEnabled is bool) {
        AdConfig.adsEnabled = rawEnabled;
      } else if (rawEnabled is num) {
        AdConfig.adsEnabled = rawEnabled != 0;
      } else if (rawEnabled is String) {
        AdConfig.adsEnabled = rawEnabled.toLowerCase() == 'true';
      }
      adsEnabledNotifier.value = AdConfig.adsEnabled;
    }

    // home_banner_id / homeBannerId
    final rawHomeBanner =
        (map['home_banner_id'] ?? map['homeBannerId'])?.toString().trim();
    if (rawHomeBanner != null && rawHomeBanner.isNotEmpty) {
      AdConfig.homeBannerId = rawHomeBanner;
    }

    // detail_banner_id / detailBannerId
    final rawDetailBanner =
        (map['detail_banner_id'] ?? map['detailBannerId'])?.toString().trim();
    if (rawDetailBanner != null && rawDetailBanner.isNotEmpty) {
      AdConfig.detailBannerId = rawDetailBanner;
    }

    // interstitial_id / interstitialId
    final rawInterstitial =
        (map['interstitial_id'] ?? map['interstitialId'])?.toString().trim();
    if (rawInterstitial != null && rawInterstitial.isNotEmpty) {
      AdConfig.interstitialId = rawInterstitial;
    }

    // android_app_id / androidAppId
    final rawAppId =
        (map['android_app_id'] ?? map['androidAppId'])?.toString().trim();
    if (rawAppId != null && rawAppId.isNotEmpty) {
      AdConfig.androidAppId = rawAppId;
    }

    // interstitial_cooldown_seconds / interstitialCooldown
    final rawCooldown = map['interstitial_cooldown_seconds'] ??
        map['interstitial_cooldown'] ??
        map['interstitialCooldown'];
    if (rawCooldown != null) {
      int seconds = 180;
      if (rawCooldown is int) {
        seconds = rawCooldown;
      } else if (rawCooldown is num) {
        seconds = rawCooldown.toInt();
      } else {
        seconds = int.tryParse(rawCooldown.toString()) ?? 180;
      }
      // If provided in minutes (e.g. <= 10), convert to seconds
      if (seconds > 0 && seconds <= 10) {
        seconds = seconds * 60;
      }
      AdConfig.interstitialCooldown = Duration(seconds: seconds);
    }

    _saveToCache(map);

    debugPrint('🔥 [Realtime Ads] Synced ad configuration from Firebase:');
    debugPrint('   - adsEnabled: ${AdConfig.adsEnabled}');
    debugPrint('   - homeBannerId: ${AdConfig.homeBannerId}');
    debugPrint('   - detailBannerId: ${AdConfig.detailBannerId}');
    debugPrint('   - interstitialId: ${AdConfig.interstitialId}');
    debugPrint('   - interstitialCooldown: ${AdConfig.interstitialCooldown.inSeconds}s');
  }

  Future<void> _saveToCache(Map<String, dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cacheKey, jsonEncode(data));
    } catch (_) {}
  }

  Future<void> _loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedStr = prefs.getString(_cacheKey);
      if (cachedStr != null && cachedStr.isNotEmpty) {
        final decoded = jsonDecode(cachedStr);
        if (decoded is Map) {
          _applyData(decoded);
          debugPrint('📁 [Realtime Ads] Loaded cached ad settings from storage.');
        }
      }
    } catch (_) {}
  }

  void dispose() {
    _subscription?.cancel();
  }
}

