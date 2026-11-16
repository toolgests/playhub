import 'package:flutter/material.dart';

enum NotificationType {
  game,
  reward,
  system,
  tournament,
}

@immutable
class NotificationItem {
  const NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.timestamp,
    required this.type,
    this.gameId,
    this.imageUrl,
    this.actionUrl,
    this.isRead = false,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    final rawType = (json['type'] ?? '').toString().toLowerCase();
    final NotificationType type;
    if (rawType.contains('reward') || rawType.contains('bonus')) {
      type = NotificationType.reward;
    } else if (rawType.contains('tourn') || rawType.contains('event')) {
      type = NotificationType.tournament;
    } else if (rawType.contains('game')) {
      type = NotificationType.game;
    } else {
      type = NotificationType.system;
    }

    DateTime timestamp;
    try {
      final rawDate = json['createdAt'] ?? json['timestamp'];
      timestamp = rawDate != null
          ? (DateTime.tryParse(rawDate.toString()) ?? DateTime.now())
          : DateTime.now();
    } catch (_) {
      timestamp = DateTime.now();
    }

    return NotificationItem(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      message: (json['body'] ?? json['message'] ?? '').toString(),
      timestamp: timestamp,
      type: type,
      gameId: json['gameId']?.toString(),
      imageUrl: json['imageUrl']?.toString(),
      actionUrl: json['actionUrl']?.toString(),
      isRead: json['isRead'] == true,
    );
  }

  final String id;
  final String title;
  final String message;
  final DateTime timestamp;
  final NotificationType type;
  final String? gameId;
  final String? imageUrl;
  final String? actionUrl;
  final bool isRead;

  NotificationItem copyWith({
    String? id,
    String? title,
    String? message,
    DateTime? timestamp,
    NotificationType? type,
    String? gameId,
    String? imageUrl,
    String? actionUrl,
    bool? isRead,
  }) {
    return NotificationItem(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      timestamp: timestamp ?? this.timestamp,
      type: type ?? this.type,
      gameId: gameId ?? this.gameId,
      imageUrl: imageUrl ?? this.imageUrl,
      actionUrl: actionUrl ?? this.actionUrl,
      isRead: isRead ?? this.isRead,
    );
  }
}
