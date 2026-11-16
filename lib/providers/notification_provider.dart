import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../models/notification_item.dart';
import '../services/fcm_service.dart';
import 'core_providers.dart';

class NotificationsNotifier extends Notifier<List<NotificationItem>> {
  static const _readKey = 'notification_read_ids_v1';
  static const _dismissedKey = 'notification_dismissed_ids_v1';
  static const _cacheKey = 'notification_cached_json_v1';

  static List<NotificationItem> _defaultNotifications() {
    final now = DateTime.now();
    return [
      NotificationItem(
        id: 'notif_trending_1',
        title: '🎮 New Trending Game Added!',
        message:
            'Piece of Cake: Merge & Bake is trending right now! Tap to jump in and play instantly.',
        timestamp: now.subtract(const Duration(minutes: 15)),
        type: NotificationType.game,
        gameId: '97426',
      ),
      NotificationItem(
        id: 'notif_reward_1',
        title: '⚡ Daily Play Streak Active!',
        message:
            'You earned your daily gaming bonus. Keep playing your favorite games to maintain your streak!',
        timestamp: now.subtract(const Duration(hours: 2, minutes: 20)),
        type: NotificationType.reward,
      ),
      NotificationItem(
        id: 'notif_tourney_1',
        title: '🏆 Weekend High-Score Challenge',
        message:
            'Can you beat the top score in Arcade & Puzzle games? Compete and test your skills today!',
        timestamp: now.subtract(const Duration(hours: 6)),
        type: NotificationType.tournament,
      ),
      NotificationItem(
        id: 'notif_welcome_1',
        title: '✨ Welcome to PlayHub!',
        message:
            'Browse and play thousands of curated instant games without waiting for downloads.',
        timestamp: now.subtract(const Duration(days: 2)),
        type: NotificationType.system,
      ),
    ];
  }

  @override
  List<NotificationItem> build() {
    final prefs = ref.watch(sharedPrefsProvider);
    final readIds = prefs.getStringList(_readKey)?.toSet() ?? <String>{};
    final dismissedIds =
        prefs.getStringList(_dismissedKey)?.toSet() ?? <String>{};

    // 1. Check if we have cached notifications from API
    List<NotificationItem> initial = [];
    final cachedRaw = prefs.getString(_cacheKey);
    if (cachedRaw != null && cachedRaw.isNotEmpty) {
      try {
        final decoded = jsonDecode(cachedRaw);
        if (decoded is List) {
          initial = decoded
              .whereType<Map<String, dynamic>>()
              .map(NotificationItem.fromJson)
              .toList();
        }
      } catch (_) {}
    }

    if (initial.isEmpty) {
      initial = _defaultNotifications();
    }

    // Attach real-time FCM foreground listener
    FcmService.instance.onForegroundNotification = (newItem) {
      final currentRead =
          ref.read(sharedPrefsProvider).getStringList(_readKey)?.toSet() ??
              <String>{};
      final currentDismissed =
          ref.read(sharedPrefsProvider).getStringList(_dismissedKey)?.toSet() ??
              <String>{};
      if (currentDismissed.contains(newItem.id)) return;
      state = [
        newItem.copyWith(isRead: currentRead.contains(newItem.id)),
        ...state.where((n) => n.id != newItem.id),
      ];
    };

    // Trigger background live fetch
    Future.microtask(_fetchLiveNotifications);

    return initial
        .where((n) => !dismissedIds.contains(n.id))
        .map((n) => n.copyWith(isRead: readIds.contains(n.id)))
        .toList(growable: false);
  }

  Future<void> refresh() async {
    await _fetchLiveNotifications();
  }

  Future<void> _fetchLiveNotifications() async {
    debugPrint(
      '🔔 [Notifications API] Fetching live notifications from: ${AppConfig.notificationsApiUrl}',
    );

    try {
      final uri = Uri.parse(AppConfig.notificationsApiUrl);
      final headers = <String, String>{
        'Accept': 'application/json',
      };
      if (!kIsWeb) {
        headers['User-Agent'] =
            'Mozilla/5.0 (Linux; Android 14; PlayHub Mobile App) AppleWebKit/537.36';
      }

      final response = await http.get(
        uri,
        headers: headers,
      ).timeout(const Duration(seconds: 15));

      debugPrint(
        '📥 [Notifications API] HTTP Status: ${response.statusCode} ${response.reasonPhrase}',
      );

      if (response.statusCode == 200) {
        final raw = response.body;
        debugPrint('📄 [Notifications API] Raw JSON Response:\n$raw');

        final decoded = jsonDecode(raw);

        List<dynamic> itemsJson = [];
        if (decoded is Map<String, dynamic> &&
            decoded['notifications'] is List) {
          itemsJson = decoded['notifications'] as List;
        } else if (decoded is List) {
          itemsJson = decoded;
        }

        debugPrint(
          '🔔 [Notifications API] Decoded ${itemsJson.length} items from JSON',
        );

        if (itemsJson.isNotEmpty) {
          final prefs = ref.read(sharedPrefsProvider);
          final readIds = prefs.getStringList(_readKey)?.toSet() ?? <String>{};
          final dismissedIds =
              prefs.getStringList(_dismissedKey)?.toSet() ?? <String>{};

          final liveList = itemsJson
              .whereType<Map<String, dynamic>>()
              .map(NotificationItem.fromJson)
              .toList();

          // Cache the raw JSON for fast instant offline display
          await prefs.setString(_cacheKey, jsonEncode(itemsJson));

          state = liveList
              .where((n) => !dismissedIds.contains(n.id))
              .map((n) => n.copyWith(isRead: readIds.contains(n.id)))
              .toList(growable: false);

          debugPrint(
            '✅ [Notifications API] SUCCESS! Updated UI with ${state.length} notifications (${state.where((n) => !n.isRead).length} unread).',
          );
        }
      } else {
        debugPrint('❌ [Notifications API] Non-200 Response: ${response.body}');
      }
    } catch (e, st) {
      debugPrint('❌ [Notifications API] Error fetching notifications: $e\n$st');
    }
  }

  void markAsRead(String id) {
    final next = state.map((n) {
      if (n.id == id) return n.copyWith(isRead: true);
      return n;
    }).toList(growable: false);

    state = next;
    _saveReadIds(next.where((n) => n.isRead).map((n) => n.id).toList());
  }

  void markAllAsRead() {
    final next = state.map((n) => n.copyWith(isRead: true)).toList(growable: false);
    state = next;
    _saveReadIds(next.map((n) => n.id).toList());
  }

  void deleteNotification(String id) {
    final next = state.where((n) => n.id != id).toList(growable: false);
    state = next;

    final prefs = ref.read(sharedPrefsProvider);
    final dismissed = prefs.getStringList(_dismissedKey)?.toSet() ?? <String>{};
    dismissed.add(id);
    prefs.setStringList(_dismissedKey, dismissed.toList());
  }

  void clearAll() {
    final allIds = state.map((n) => n.id).toList();
    state = const <NotificationItem>[];

    final prefs = ref.read(sharedPrefsProvider);
    final dismissed = prefs.getStringList(_dismissedKey)?.toSet() ?? <String>{};
    dismissed.addAll(allIds);
    prefs.setStringList(_dismissedKey, dismissed.toList());
  }

  void _saveReadIds(List<String> readIds) {
    ref.read(sharedPrefsProvider).setStringList(_readKey, readIds);
  }
}

final notificationsProvider =
    NotifierProvider<NotificationsNotifier, List<NotificationItem>>(
  NotificationsNotifier.new,
);

final unreadNotificationsCountProvider = Provider<int>((ref) {
  final list = ref.watch(notificationsProvider);
  return list.where((n) => !n.isRead).length;
});
