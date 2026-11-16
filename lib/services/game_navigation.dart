import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/game.dart';
import '../providers/library_providers.dart';
import '../providers/preview_video_provider.dart';
import '../screens/game_detail_screen.dart';
import '../screens/player_screen.dart';
import 'ad_service.dart';

Future<void> openGameDetail(
  BuildContext context,
  Game game, {
  Object? heroTag,
}) {
  return Navigator.of(context).push<void>(
    MaterialPageRoute<void>(
      builder: (_) => GameDetailScreen(game: game, heroTag: heroTag),
    ),
  );
}

/// Opens the full-screen player, records the game as recently played,
/// pauses card previews while it runs, and offers the post-game
/// interstitial after the player closes.
Future<void> playGame(BuildContext context, WidgetRef ref, Game game) async {
  ref.read(recentlyPlayedProvider.notifier).add(game.id);
  final previews = ref.read(previewVideoManagerProvider);
  final navigator = Navigator.of(context);

  previews.suspend();
  try {
    await navigator.push<void>(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 280),
        reverseTransitionDuration: const Duration(milliseconds: 200),
        pageBuilder: (_, __, ___) => PlayerScreen(game: game),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  } finally {
    previews.resume();
  }

  await AdService.instance.maybeShowInterstitial();
}
