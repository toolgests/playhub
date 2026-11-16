import 'package:flutter/foundation.dart';

@immutable
class AppSettings {
  const AppSettings({
    this.darkMode = true,
    this.autoplayPreviews = true,
    this.wifiOnly = false,
    this.noticeAccepted = false,
  });

  final bool darkMode;
  final bool autoplayPreviews;
  final bool wifiOnly;
  final bool noticeAccepted;

  AppSettings copyWith({
    bool? darkMode,
    bool? autoplayPreviews,
    bool? wifiOnly,
    bool? noticeAccepted,
  }) {
    return AppSettings(
      darkMode: darkMode ?? this.darkMode,
      autoplayPreviews: autoplayPreviews ?? this.autoplayPreviews,
      wifiOnly: wifiOnly ?? this.wifiOnly,
      noticeAccepted: noticeAccepted ?? this.noticeAccepted,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is AppSettings &&
      other.darkMode == darkMode &&
      other.autoplayPreviews == autoplayPreviews &&
      other.wifiOnly == wifiOnly &&
      other.noticeAccepted == noticeAccepted;

  @override
  int get hashCode =>
      Object.hash(darkMode, autoplayPreviews, wifiOnly, noticeAccepted);
}
