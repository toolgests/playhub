import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/game.dart';
import '../../widgets/common.dart';
import '../../widgets/game_mini_tile.dart';

/// Horizontal rail for external games from the live API.
class ExternalGamesRow extends ConsumerWidget {
  const ExternalGamesRow({
    super.key,
    required this.heading,
    required this.games,
  });

  final String heading;
  final List<Game> games;

  static const double _tileWidth = 145;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (games.isEmpty) return const SizedBox.shrink();

    final height =
        GameMiniTile.heightFor(_tileWidth, MediaQuery.textScalerOf(context));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: heading.isNotEmpty ? heading : 'PlayHub External Games',
          trailing: '${games.length} games',
        ),
        SizedBox(
          height: height,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: games.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) => GameMiniTile(
              key: ValueKey<String>('ext_${games[index].id}'),
              game: games[index],
              section: 'external',
              playOnTap: false,
              width: _tileWidth,
            ),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}
