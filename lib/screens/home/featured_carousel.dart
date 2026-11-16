import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/game.dart';
import '../../services/game_navigation.dart';
import '../../theme/app_colors.dart';
import '../../utils/genre_style.dart';
import '../../widgets/chips.dart';
import '../../widgets/common.dart';
import '../../widgets/favorite_heart.dart';
import '../../widgets/preview_media.dart';

/// Large auto-sliding cards with gameplay previews using carousel_slider.
class FeaturedCarousel extends ConsumerStatefulWidget {
  const FeaturedCarousel({super.key, required this.games});

  final List<Game> games;

  @override
  ConsumerState<FeaturedCarousel> createState() => _FeaturedCarouselState();
}

class _FeaturedCarouselState extends ConsumerState<FeaturedCarousel> {
  final CarouselSliderController _carouselController =
      CarouselSliderController();
  int _current = 0;

  int get _count => widget.games.length;

  @override
  Widget build(BuildContext context) {
    if (_count == 0) return const SizedBox.shrink();
    final width = MediaQuery.sizeOf(context).width;
    final cardHeight = (width * 0.88 * 0.6).clamp(180.0, 340.0).toDouble();

    return Column(
      children: [
        const SectionHeader(title: 'Featured'),
        CarouselSlider.builder(
          carouselController: _carouselController,
          itemCount: _count,
          itemBuilder: (context, index, realIndex) {
            final game = widget.games[index];
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
              child: _FeaturedCard(
                game: game,
                slotKey: 'featured_${game.id}',
              ),
            );
          },
          options: CarouselOptions(
            height: cardHeight,
            viewportFraction: 0.88,
            initialPage: 0,
            enableInfiniteScroll: _count > 1,
            autoPlay: _count > 1,
            autoPlayInterval: const Duration(seconds: 5),
            autoPlayAnimationDuration: const Duration(milliseconds: 650),
            autoPlayCurve: Curves.easeInOutCubic,
            enlargeCenterPage: false,
            onPageChanged: (index, reason) {
              setState(() => _current = index);
            },
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < _count; i++)
              GestureDetector(
                onTap: () => _carouselController.animateToPage(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.easeOutCubic,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: i == _current ? 20 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    gradient: i == _current ? AppColors.primaryGradient : null,
                    color: i == _current
                        ? null
                        : Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _FeaturedCard extends ConsumerWidget {
  const _FeaturedCard({required this.game, required this.slotKey});

  final Game game;
  final String slotKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final genre = game.primaryGenre;
    final heroTag = 'hero_$slotKey';

    return GestureDetector(
      onTap: () => openGameDetail(context, game, heroTag: heroTag),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppColors.violet.withValues(alpha: 0.32),
              blurRadius: 26,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            fit: StackFit.expand,
            children: [
              PreviewMedia(
                game: game,
                slotKey: slotKey,
                priority: 1,
                heroTag: heroTag,
              ),
              const IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: [0.35, 1.0],
                      colors: [Color(0x000F0B1F), Color(0xF00F0B1F)],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: FavoriteHeart(gameId: game.id, size: 20),
              ),
              Positioned(
                left: 16,
                right: 16,
                bottom: 14,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (genre != null) ...[
                            GenreTag(label: genreLabel(genre), large: true),
                            const SizedBox(height: 8),
                          ],
                          Text(
                            game.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              height: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    _PlayPill(onTap: () => playGame(context, ref, game)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlayPill extends StatelessWidget {
  const _PlayPill({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Play',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: AppColors.pink.withValues(alpha: 0.45),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.play_arrow_rounded,
                  color: Colors.white, size: 20),
              const SizedBox(width: 4),
              Text(
                'PLAY',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
