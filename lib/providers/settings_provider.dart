import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_settings.dart';
import 'core_providers.dart';

class SettingsNotifier extends Notifier<AppSettings> {
  static const _kDarkMode = 'settings_dark_mode';
  static const _kAutoplay = 'settings_autoplay_previews';
  static const _kWifiOnly = 'settings_wifi_only';
  static const _kNotice = 'settings_notice_accepted';

  @override
  AppSettings build() {
    final prefs = ref.watch(sharedPrefsProvider);
    return AppSettings(
      darkMode: prefs.getBool(_kDarkMode) ?? true,
      autoplayPreviews: prefs.getBool(_kAutoplay) ?? true,
      wifiOnly: prefs.getBool(_kWifiOnly) ?? false,
      noticeAccepted: prefs.getBool(_kNotice) ?? false,
    );
  }

  void setDarkMode(bool value) {
    state = state.copyWith(darkMode: value);
    ref.read(sharedPrefsProvider).setBool(_kDarkMode, value);
  }

  void setAutoplayPreviews(bool value) {
    state = state.copyWith(autoplayPreviews: value);
    ref.read(sharedPrefsProvider).setBool(_kAutoplay, value);
  }

  void setWifiOnly(bool value) {
    state = state.copyWith(wifiOnly: value);
    ref.read(sharedPrefsProvider).setBool(_kWifiOnly, value);
  }

  void setNoticeAccepted(bool value) {
    state = state.copyWith(noticeAccepted: value);
    ref.read(sharedPrefsProvider).setBool(_kNotice, value);
  }
}

final settingsProvider =
    NotifierProvider<SettingsNotifier, AppSettings>(SettingsNotifier.new);
