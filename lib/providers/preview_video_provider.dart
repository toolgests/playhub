import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/preview_video_manager.dart';
import 'network_provider.dart';
import 'settings_provider.dart';

/// Single shared manager for card video previews. Settings and network
/// changes are pushed into it from the root widget (see app.dart).
final previewVideoManagerProvider = Provider<PreviewVideoManager>((ref) {
  final settings = ref.read(settingsProvider);
  final manager = PreviewVideoManager()
    ..updatePolicy(
      autoplay: settings.autoplayPreviews,
      wifiOnly: settings.wifiOnly,
    );
  final network = ref.read(networkStatusProvider).asData?.value;
  if (network != null) {
    manager.updateNetwork(online: network.online, wifi: network.wifi);
  }
  ref.onDispose(manager.dispose);
  return manager;
});
