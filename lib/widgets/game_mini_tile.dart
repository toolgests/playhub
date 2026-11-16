import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/game.dart';
import '../services/game_navigation.dart';
import '../theme/app_colors.dart';
import 'game_card.dart';
import 'game_image.dart';

/// Compact tile for horizontal rails (Continue Playing, More like this).
class GameMiniTile extends ConsumerWidget {
  const GameMiniTile({
    super.key,
    required this.game,
    required this.section,
    this.playOnTap = false,
    this.width = 140,
  });

  final Game game;
  final String section;

  /// When true, tapping launches the game and long press opens details.
  final bool playOnTap;
  final double width;

  static double heightFor(double width, TextScaler scaler) =>
      width * 0.7 + 8 + scaler.scale(13) * 1.4 + 4;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final heroTag = 'hero_${section}_${game.id}';

    void openDetail() => openGameDetail(context, game, heroTag: heroTag);

    return SizedBox(
      width: width,
      child: GestureDetector(
        onTap: playOnTap ? () => playGame(context, ref, game) : openDetail,
        onLongPress: playOnTap ? openDetail : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: width * 0.7,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.violet.withValues(alpha: 0.18),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Hero(
                      tag: heroTag,
                      child: GameImage(url: game.previewImage),
                    ),
                    const IgnorePointer(
                      child: DecoratedBox(
                        decoration:
                            BoxDecoration(gradient: AppColors.imageScrim),
                      ),
                    ),
                    if (playOnTap)
                      const Center(child: PlayBadge(size: 36))
                    else
                      const Positioned(
                        right: 6,
                        bottom: 6,
                        child: PlayBadge(size: 26),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              game.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 13,
                height: 1.4,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
