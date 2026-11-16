import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../firebase_options.dart';
import 'fcm_service.dart';
import 'realtime_ad_service.dart';
import 'remote_config_service.dart';

/// Central Firebase Orchestrator for PlayHub.
/// Initializes Firebase, FCM, and Remote Config safely.
class FirebaseService {
  FirebaseService._();

  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;

    try {
      // 1. Initialize Core Firebase
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      _initialized = true;
      debugPrint('🔥 [Firebase] Core initialized successfully.');

      // 2. Set Background FCM Handler (must be registered early)
      if (!kIsWeb) {
        FirebaseMessaging.onBackgroundMessage(
          firebaseMessagingBackgroundHandler,
        );
      }

      // 3. Initialize Firebase Cloud Messaging
      await FcmService.instance.initialize();

      // 4. Initialize Firebase Remote Config (Exclusively for App Update)
      await RemoteConfigService.instance.initialize();

      // 5. Initialize Firebase Realtime Database for Dynamic Ad Control
      await RealtimeAdService.instance.initialize();
    } catch (e, st) {
      debugPrint('⚠️ [Firebase] Initialization failed: $e\n$st');
    }
  }
}

