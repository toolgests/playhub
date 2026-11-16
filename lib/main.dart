import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:visibility_detector/visibility_detector.dart';

import 'app.dart';
import 'providers/core_providers.dart';
import 'services/firebase_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase Core, Cloud Messaging (FCM), & Remote Config
  await FirebaseService.initialize();

  await SystemChrome.setPreferredOrientations(
    const [DeviceOrientation.portraitUp],
  );
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  // Bounded decoded-image cache for long, image-heavy grids.
  final imageCache = PaintingBinding.instance.imageCache;
  imageCache.maximumSize = 200;
  imageCache.maximumSizeBytes = 80 << 20;

  VisibilityDetectorController.instance.updateInterval =
      const Duration(milliseconds: 200);

  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [sharedPrefsProvider.overrideWithValue(prefs)],
      child: const PlayHubApp(),
    ),
  );
}
