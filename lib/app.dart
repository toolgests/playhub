import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'config/app_config.dart';
import 'models/app_settings.dart';
import 'providers/network_provider.dart';
import 'providers/preview_video_provider.dart';
import 'providers/settings_provider.dart';
import 'screens/splash_screen.dart';
import 'theme/app_theme.dart';

class PlayHubApp extends ConsumerWidget {
  const PlayHubApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final darkMode = ref.watch(settingsProvider.select((s) => s.darkMode));
    final previews = ref.watch(previewVideoManagerProvider);

    // The root widget is always mounted, so it relays settings and network
    // changes to the preview manager.
    ref.listen<AppSettings>(settingsProvider, (_, next) {
      previews.updatePolicy(
        autoplay: next.autoplayPreviews,
        wifiOnly: next.wifiOnly,
      );
    });
    ref.listen<AsyncValue<NetworkStatus>>(networkStatusProvider, (_, next) {
      final status = next.asData?.value;
      if (status != null) {
        previews.updateNetwork(online: status.online, wifi: status.wifi);
      }
    });

    return MaterialApp(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: darkMode ? ThemeMode.dark : ThemeMode.light,
      themeAnimationDuration: const Duration(milliseconds: 350),
      builder: (context, child) {
        final dark = Theme.of(context).brightness == Brightness.dark;
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: dark ? AppTheme.overlayOnDark : AppTheme.overlayOnLight,
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: const SplashScreen(),
    );
  }
}
