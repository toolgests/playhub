import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/library_providers.dart';
import '../providers/navigation_provider.dart';
import '../widgets/common.dart';
import '../widgets/paged_game_grid.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final games = ref.watch(favoriteGamesProvider);

    return PagedGameScrollView(
      games: games,
      section: 'favorites',
      headerSlivers: [
        SliverToBoxAdapter(
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Favorites', style: theme.textTheme.headlineSmall),
                  const SizedBox(height: 4),
                  Text(
                    games.isEmpty
                        ? 'Your saved games live here'
                        : '${games.length} saved ${games.length == 1 ? 'game' : 'games'}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 8)),
      ],
      emptyState: EmptyState(
        icon: Icons.favorite_rounded,
        title: 'No favorites yet',
        message:
            'Tap the heart on any game, or long press its card, to save it here.',
        actionLabel: 'Browse games',
        onAction: () => ref.read(shellTabProvider.notifier).select(0),
      ),
    );
  }
}
