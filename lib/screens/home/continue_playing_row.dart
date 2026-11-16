import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/library_providers.dart';
import '../../widgets/common.dart';
import '../../widgets/game_mini_tile.dart';

/// Recently played games. Tap resumes play, long press opens details.
class ContinuePlayingRow extends ConsumerWidget {
  const ContinuePlayingRow({super.key});

  static const double _tileWidth = 140;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final games = ref.watch(recentGamesProvider);
    if (games.isEmpty) return const SizedBox.shrink();

    final height =
        GameMiniTile.heightFor(_tileWidth, MediaQuery.textScalerOf(context));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Continue Playing'),
        SizedBox(
          height: height,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: games.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) => GameMiniTile(
              key: ValueKey<String>(games[index].id),
              game: games[index],
              section: 'recent',
              playOnTap: true,
              width: _tileWidth,
            ),
          ),
        ),
      ],
    );
  }
}
