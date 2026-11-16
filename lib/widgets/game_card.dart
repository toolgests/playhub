import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/game.dart';
import '../providers/library_providers.dart';
import '../services/game_navigation.dart';
import '../theme/app_colors.dart';
import '../utils/genre_style.dart';
import 'chips.dart';
import 'favorite_heart.dart';
import 'preview_media.dart';

/// Grid card: preview image or clip, genre tag, heart, play badge and title.
class GameCard extends ConsumerStatefulWidget {
  const GameCard({super.key, required this.game, required this.section});

  final Game game;

  /// Screen section, used to build unique preview slot and hero keys.
  final String section;

  static const double _padding = 6;
  static const double _gap = 8;
  static const double _titleSize = 13;
  static const double _titleLineHeight = 1.3;
  static const double imageAspect = 0.75;

  static double _titleHeight(TextScaler scaler) =>
      scaler.scale(_titleSize) * _titleLineHeight * 2 + 2;

  /// Total card height for a given column width, used as the grid extent.
  static double extentFor(double width, TextScaler scaler) {
    final imageHeight = (width - _padding * 2) * imageAspect;
    return _padding * 2 + imageHeight + _gap + _titleHeight(scaler) + 2;
  }

  @override
  ConsumerState<GameCard> createState() => _GameCardState();
}

class _GameCardState extends ConsumerState<GameCard> {
  bool _pressed = false;

  String get _slotKey => '${widget.section}_${widget.game.id}';

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  void _quickFavorite() {
    HapticFeedback.mediumImpact();
    final added =
        ref.read(favoritesProvider.notifier).toggle(widget.game.id);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 2),
          content: Text(
            added
                ? '${widget.game.title} added to favorites'
                : '${widget.game.title} removed from favorites',
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final game = widget.game;
    final genre = game.primaryGenre;
    final scaler = MediaQuery.textScalerOf(context);

    return Semantics(
      button: true,
      label: game.title,
      hint: 'Opens game details. Long press to save to favorites.',
      child: GestureDetector(
        onTapDown: (_) => _setPressed(true),
        onTapUp: (_) => _setPressed(false),
        onTapCancel: () => _setPressed(false),
        onTap: () => openGameDetail(context, game, heroTag: 'hero_$_slotKey'),
        onLongPress: _quickFavorite,
        child: AnimatedScale(
          scale: _pressed ? 0.96 : 1,
          duration: const Duration(milliseconds: 130),
          curve: Curves.easeOut,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: dark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.white.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: dark
                    ? Colors.white.withValues(alpha: 0.08)
                    : AppColors.violet.withValues(alpha: 0.10),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.violet.withValues(alpha: dark ? 0.16 : 0.10),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(GameCard._padding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          PreviewMedia(
                            game: game,
                            slotKey: _slotKey,
                            heroTag: 'hero_$_slotKey',
                          ),
                          const IgnorePointer(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: AppColors.imageScrim,
                              ),
                            ),
                          ),
                          if (genre != null)
                            Positioned(
                              left: 8,
                              top: 8,
                              right: 44,
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: GenreTag(label: genreLabel(genre)),
                              ),
                            ),
                          Positioned(
                            right: 6,
                            top: 6,
                            child: FavoriteHeart(gameId: game.id),
                          ),
                          const Positioned(
                            right: 8,
                            bottom: 8,
                            child: PlayBadge(),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: GameCard._gap),
                  SizedBox(
                    height: GameCard._titleHeight(scaler),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        game.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontSize: GameCard._titleSize,
                          height: GameCard._titleLineHeight,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 320.ms).moveY(begin: 10, end: 0, duration: 320.ms);
  }
}

class PlayBadge extends StatelessWidget {
  const PlayBadge({super.key, this.size = 30});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppColors.primaryGradient,
        boxShadow: [
          BoxShadow(
            color: AppColors.pink.withValues(alpha: 0.45),
            blurRadius: 10,
          ),
        ],
      ),
      child: Icon(
        Icons.play_arrow_rounded,
        color: Colors.white,
        size: size * 0.66,
      ),
    );
  }
}
