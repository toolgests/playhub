import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../firebase_options.dart';
import '../models/notification_item.dart';

/// Top-level background message handler required by Firebase Messaging.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (_) {}

  debugPrint('📩 [FCM Background] Message ID: ${message.messageId}');
  debugPrint('   Title: ${message.notification?.title}');
  debugPrint('   Body: ${message.notification?.body}');
  debugPrint('   Data: ${message.data}');

  // Store in shared preferences cache so app has it when opened
  await _cacheBackgroundMessage(message);
}

Future<void> _cacheBackgroundMessage(RemoteMessage message) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    const cacheKey = 'notification_cached_json_v1';
    final existingRaw = prefs.getString(cacheKey);
    List<dynamic> list = [];
    if (existingRaw != null && existingRaw.isNotEmpty) {
      try {
        final decoded = jsonDecode(existingRaw);
        if (decoded is List) list = decoded;
      } catch (_) {}
    }

    final itemMap = _remoteMessageToMap(message);
    // Put at top of list if not already present
    final id = itemMap['id'];
    list.removeWhere((e) => e is Map && e['id'] == id);
    list.insert(0, itemMap);

    await prefs.setString(cacheKey, jsonEncode(list));
  } catch (e) {
    debugPrint('⚠️ [FCM] Error caching background message: $e');
  }
}

Map<String, dynamic> _remoteMessageToMap(RemoteMessage message) {
  final notif = message.notification;
  final data = message.data;
  final id = message.messageId ??
      data['id'] ??
      'fcm_${DateTime.now().millisecondsSinceEpoch}';

  return {
    'id': id,
    'title': notif?.title ?? data['title'] ?? 'PlayHub Update',
    'body': notif?.body ?? data['body'] ?? data['message'] ?? '',
    'type': data['type'] ?? 'system',
    'gameId': data['gameId'] ?? data['game_id'],
    'imageUrl': notif?.android?.imageUrl ?? data['imageUrl'] ?? data['image'],
    'actionUrl': data['actionUrl'] ?? data['url'],
    'createdAt': DateTime.now().toIso8601String(),
    'isRead': false,
  };
}

/// Firebase Cloud Messaging (FCM) Service
class FcmService {
  FcmService._();
  static final FcmService instance = FcmService._();

  FirebaseMessaging get _messaging => FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _androidChannel =
      AndroidNotificationChannel(
    'playhub_general',
    'PlayHub Notifications',
    description: 'Instant game alerts, daily rewards and tournaments',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
  );

  String? _fcmToken;
  bool _initialized = false;

  String? get fcmToken => _fcmToken;

  /// Callback when a notification with deep link or gameId is tapped
  void Function(NotificationItem item)? onNotificationTapped;

  /// Callback when a foreground notification arrives
  void Function(NotificationItem item)? onForegroundNotification;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    try {
      // 1. Request notification permission (Android 13+ and iOS/Web)
      final settings = await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      debugPrint(
        '🔔 [FCM] Notification authorization status: ${settings.authorizationStatus}',
      );

      // Set foreground presentation options for iOS/macOS
      await _messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // 2. Setup Local Notifications & Android Notification Channel
      if (!kIsWeb) {
        const androidInit =
            AndroidInitializationSettings('@mipmap/ic_launcher');
        const initSettings = InitializationSettings(android: androidInit);

        await _localNotifications.initialize(
          initSettings,
          onDidReceiveNotificationResponse: (response) {
            final payload = response.payload;
            if (payload != null && payload.isNotEmpty) {
              try {
                final map = jsonDecode(payload) as Map<String, dynamic>;
                final item = NotificationItem.fromJson(map);
                onNotificationTapped?.call(item);
              } catch (_) {}
            }
          },
        );

        final androidPlugin =
            _localNotifications.resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();
        if (androidPlugin != null) {
          await androidPlugin.createNotificationChannel(_androidChannel);
          await androidPlugin.requestNotificationsPermission();
        }
      }

      // 3. Fetch and print FCM Device Token for push testing
      await _fetchAndLogToken();

      // Listen for token refreshes
      _messaging.onTokenRefresh.listen((newToken) {
        _fcmToken = newToken;
        debugPrint('🔑 [FCM] Token refreshed: $newToken');
      });

      // 4. Subscribe to global default topics
      if (!kIsWeb) {
        await _messaging.subscribeToTopic('all_users');
        await _messaging.subscribeToTopic('game_alerts');
        debugPrint('📡 [FCM] Subscribed to topics: "all_users", "game_alerts"');
      }

      // 5. Foreground notification stream (displays heads-up banner via local notifications)
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('📩 [FCM Foreground] Received: ${message.messageId}');
        debugPrint('   Title: ${message.notification?.title}');
        debugPrint('   Body: ${message.notification?.body}');
        debugPrint('   Data: ${message.data}');

        final itemMap = _remoteMessageToMap(message);
        final notifItem = NotificationItem.fromJson(itemMap);
        _cacheBackgroundMessage(message);
        onForegroundNotification?.call(notifItem);

        // Display heads-up notification in the system tray when app is in foreground
        if (!kIsWeb) {
          final notif = message.notification;
          final title = (notif?.title ?? itemMap['title'] ?? '').toString();
          final body = (notif?.body ?? itemMap['body'] ?? '').toString();

          if (title.isNotEmpty || body.isNotEmpty) {
            _localNotifications.show(
              message.hashCode,
              title,
              body,
              NotificationDetails(
                android: AndroidNotificationDetails(
                  _androidChannel.id,
                  _androidChannel.name,
                  channelDescription: _androidChannel.description,
                  importance: Importance.max,
                  priority: Priority.high,
                  icon: '@mipmap/ic_launcher',
                  playSound: true,
                  enableVibration: true,
                ),
              ),
              payload: jsonEncode(itemMap),
            );
          }
        }
      });

      // 6. App opened from background notification tap
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('🚀 [FCM] Opened from background: ${message.messageId}');
        final itemMap = _remoteMessageToMap(message);
        final notifItem = NotificationItem.fromJson(itemMap);
        onNotificationTapped?.call(notifItem);
      });

      // 7. App launched from terminated state via notification
      final initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        debugPrint('🚀 [FCM] Initial notification: ${initialMessage.messageId}');
        final itemMap = _remoteMessageToMap(initialMessage);
        final notifItem = NotificationItem.fromJson(itemMap);
        Future.delayed(const Duration(milliseconds: 500), () {
          onNotificationTapped?.call(notifItem);
        });
      }
    } catch (e, st) {
      debugPrint('⚠️ [FCM] Failed to initialize FCM: $e\n$st');
    }
  }

  Future<void> _fetchAndLogToken() async {
    try {
      if (kIsWeb) {
        _fcmToken = await _messaging.getToken(
          vapidKey: null,
        );
      } else {
        _fcmToken = await _messaging.getToken();
      }

      if (_fcmToken != null) {
        debugPrint('====================================================');
        debugPrint('🔑 [FCM Registration Token]:');
        debugPrint(_fcmToken);
        debugPrint('====================================================');
      }
    } catch (e) {
      debugPrint('⚠️ [FCM] Could not get FCM token: $e');
    }
  }

  /// Sends a local test notification directly to the device status bar.
  Future<void> showTestNotification() async {
    if (kIsWeb) return;
    try {
      final now = DateTime.now();
      await _localNotifications.show(
        now.millisecondsSinceEpoch ~/ 1000,
        '🎮 PlayHub: Test Notification',
        'Notification system is active and working perfectly! Tap to play.',
        NotificationDetails(
          android: AndroidNotificationDetails(
            _androidChannel.id,
            _androidChannel.name,
            channelDescription: _androidChannel.description,
            importance: Importance.max,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
            playSound: true,
            enableVibration: true,
          ),
        ),
      );
    } catch (e) {
      debugPrint('⚠️ [FCM] Error showing test notification: $e');
    }
  }
}
