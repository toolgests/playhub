import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/catalog_providers.dart';
import '../utils/genre_style.dart';
import '../widgets/common.dart';
import '../widgets/gradient_background.dart';
import '../widgets/paged_game_grid.dart';

class CategoryGamesScreen extends ConsumerWidget {
  const CategoryGamesScreen({super.key, required this.genre});

  final String genre;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final games = ref.watch(gamesByGenreProvider(genre));
    final label = genreLabel(genre);

    return Scaffold(
      body: GradientBackground(
        child: PagedGameScrollView(
          games: games,
          section: 'genre_$genre',
          headerSlivers: [
            SliverAppBar(
              pinned: true,
              title: Text(label),
              backgroundColor: Theme.of(context)
                  .scaffoldBackgroundColor
                  .withValues(alpha: 0.85),
            ),
            if (games.isNotEmpty)
              SliverToBoxAdapter(
                child: SectionHeader(
                  title: '$label games',
                  trailing: '${games.length}',
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                ),
              ),
          ],
          emptyState: EmptyState(
            icon: genreIcon(genre),
            title: 'Nothing here yet',
            message: 'There are no $label games in the catalog right now.',
          ),
        ),
      ),
    );
  }
}
