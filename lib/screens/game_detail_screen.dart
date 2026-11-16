import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';

import '../config/ad_config.dart';
import '../data/video_url_resolver.dart';
import '../models/game.dart';
import '../providers/catalog_providers.dart';
import '../services/game_navigation.dart';
import '../theme/app_colors.dart';
import '../utils/genre_style.dart';
import '../utils/text_utils.dart';
import '../widgets/banner_ad_slot.dart';
import '../widgets/chips.dart';
import '../widgets/common.dart';
import '../widgets/favorite_heart.dart';
import '../widgets/game_image.dart';
import '../widgets/game_mini_tile.dart';
import '../widgets/gradient_background.dart';
import '../widgets/gradient_button.dart';
import 'category_games_screen.dart';

class GameDetailScreen extends ConsumerStatefulWidget {
  const GameDetailScreen({super.key, required this.game, this.heroTag});

  final Game game;
  final Object? heroTag;

  @override
  ConsumerState<GameDetailScreen> createState() => _GameDetailScreenState();
}

class _GameDetailScreenState extends ConsumerState<GameDetailScreen> {
  static const int _collapsedLines = 4;
  bool _expanded = false;

  late final String _description = plainText(widget.game.description);
  late final String _howToPlay = plainText(widget.game.howToPlay);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final game = widget.game;
    final similar = ref.watch(similarGamesProvider(game));
    final padding = MediaQuery.paddingOf(context);
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.72);
    final canExpand = _description.length > 180;

    final orientationLabel = game.landscapeOnly
        ? 'Landscape'
        : game.portraitOnly
            ? 'Portrait'
            : 'Any orientation';
    final orientationIcon = game.landscapeOnly
        ? Icons.stay_current_landscape_rounded
        : Icons.stay_current_portrait_rounded;

    return Scaffold(
      body: GradientBackground(
        child: Stack(
          children: [
            CustomScrollView(
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              slivers: [
                SliverToBoxAdapter(
                  child: _DetailVideoHeader(
                    game: game,
                    heroTag: widget.heroTag,
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                  sliver: SliverList.list(
                    children: [
                      Text(
                        game.title,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          height: 1.2,
                        ),
                      )
                          .animate()
                          .fadeIn(duration: 300.ms)
                          .moveY(begin: 8, end: 0),
                      const SizedBox(height: 14),
                      if (game.genres.isNotEmpty)
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final genre in game.genres.take(6))
                              GradientChip(
                                label: genreLabel(genre),
                                icon: genreIcon(genre),
                                height: 36,
                                selected: genre == game.primaryGenre,
                                onTap: () => Navigator.of(context).push<void>(
                                  MaterialPageRoute<void>(
                                    builder: (_) =>
                                        CategoryGamesScreen(genre: genre),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          InfoPill(
                              icon: orientationIcon, label: orientationLabel),
                          if (game.hasInGamePurchases)
                            const InfoPill(
                              icon: Icons.shopping_bag_rounded,
                              label: 'In-game purchases',
                            ),
                          if (game.supportedLanguages.length > 1)
                            InfoPill(
                              icon: Icons.translate_rounded,
                              label:
                                  '${game.supportedLanguages.length} languages',
                            ),
                        ],
                      ),
                      if (_description.isNotEmpty) ...[
                        const SectionHeader(
                          title: 'About this game',
                          padding: EdgeInsets.fromLTRB(0, 24, 0, 10),
                        ),
                        AnimatedSize(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeOutCubic,
                          alignment: Alignment.topCenter,
                          child: Text(
                            _description,
                            maxLines: _expanded ? null : _collapsedLines,
                            overflow: _expanded
                                ? TextOverflow.visible
                                : TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: muted,
                              height: 1.6,
                            ),
                          ),
                        ),
                        if (canExpand)
                          Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton(
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                foregroundColor: AppColors.pink,
                              ),
                              onPressed: () =>
                                  setState(() => _expanded = !_expanded),
                              child:
                                  Text(_expanded ? 'Show less' : 'Read more'),
                            ),
                          ),
                      ],
                      if (_howToPlay.isNotEmpty) ...[
                        const SectionHeader(
                          title: 'How to play',
                          padding: EdgeInsets.fromLTRB(0, 20, 0, 10),
                        ),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.cyan.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppColors.cyan.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.sports_esports_rounded,
                                color: AppColors.cyan,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _howToPlay,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: muted,
                                    height: 1.6,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      BannerAdSlot(adUnitId: AdConfig.detailBannerId),
                    ],
                  ),
                ),
                if (similar.isNotEmpty) ...[
                  const SliverToBoxAdapter(
                    child: SectionHeader(title: 'More like this'),
                  ),
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: GameMiniTile.heightFor(
                        140,
                        MediaQuery.textScalerOf(context),
                      ),
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: similar.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 12),
                        itemBuilder: (context, index) => GameMiniTile(
                          key: ValueKey<String>(similar[index].id),
                          game: similar[index],
                          section: 'similar_${game.id}',
                        ),
                      ),
                    ),
                  ),
                ],
                SliverPadding(
                  padding: EdgeInsets.only(bottom: padding.bottom + 112),
                ),
              ],
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: IgnorePointer(
                child: Container(
                  height: padding.bottom + 120,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        theme.scaffoldBackgroundColor.withValues(alpha: 0),
                        theme.scaffoldBackgroundColor.withValues(alpha: 0.95),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 20,
              right: 20,
              bottom: padding.bottom + 18,
              child: GradientButton(
                label: 'PLAY NOW',
                icon: Icons.play_arrow_rounded,
                height: 60,
                onPressed: () => playGame(context, ref, game),
              ).animate(onPlay: (c) => c.repeat()).shimmer(
                    delay: 2500.ms,
                    duration: 1400.ms,
                    color: Colors.white.withValues(alpha: 0.35),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailVideoHeader extends StatefulWidget {
  const _DetailVideoHeader({required this.game, required this.heroTag});

  final Game game;
  final Object? heroTag;

  @override
  State<_DetailVideoHeader> createState() => _DetailVideoHeaderState();
}

class _DetailVideoHeaderState extends State<_DetailVideoHeader> {
  VideoPlayerController? _controller;
  bool _initialized = false;
  bool _isMuted = true;
  String? _videoUrl;

  @override
  void initState() {
    super.initState();
    _videoUrl = resolveVideoUrl(widget.game);
    _initVideo();
  }

  Future<void> _initVideo() async {
    final url = _videoUrl;
    if (url == null || url.isEmpty) return;

    try {
      final controller = VideoPlayerController.networkUrl(
        Uri.parse(url),
        videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
      );
      await controller.initialize();
      await controller.setLooping(true);
      await controller.setVolume(0);
      await controller.play();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _controller = controller;
        _initialized = true;
      });
    } catch (_) {
      // Gracefully show static image if video playback is unsupported or network fails
    }
  }

  void _toggleMute() {
    if (_controller == null || !_initialized) return;
    setState(() {
      _isMuted = !_isMuted;
      _controller!.setVolume(_isMuted ? 0 : 1.0);
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    final game = widget.game;

    Widget imageLayer = GameImage(url: game.previewImage);
    if (widget.heroTag != null) {
      imageLayer = Hero(tag: widget.heroTag!, child: imageLayer);
    }

    return AspectRatio(
      aspectRatio: 16 / 11,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(28),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                imageLayer,
                if (_initialized && _controller != null)
                  AnimatedOpacity(
                    opacity: 1.0,
                    duration: const Duration(milliseconds: 350),
                    child: SizedBox.expand(
                      child: FittedBox(
                        fit: BoxFit.cover,
                        clipBehavior: Clip.hardEdge,
                        child: SizedBox(
                          width: _controller!.value.size.width > 0
                              ? _controller!.value.size.width
                              : 16,
                          height: _controller!.value.size.height > 0
                              ? _controller!.value.size.height
                              : 9,
                          child: VideoPlayer(_controller!),
                        ),
                      ),
                    ),
                  ),
                const IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: [0.0, 0.25, 0.7, 1.0],
                        colors: [
                          Color(0x990F0B1F),
                          Color(0x000F0B1F),
                          Color(0x000F0B1F),
                          Color(0xB30F0B1F),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: top + 8,
            left: 12,
            child: _CircleButton(
              icon: Icons.arrow_back_rounded,
              tooltip: 'Back',
              onTap: () => Navigator.of(context).maybePop(),
            ),
          ),
          Positioned(
            top: top + 8,
            right: 12,
            child: FavoriteHeart(gameId: game.id, size: 24),
          ),
          if (_initialized && _controller != null)
            Positioned(
              bottom: 12,
              right: 14,
              child: _CircleButton(
                icon: _isMuted
                    ? Icons.volume_off_rounded
                    : Icons.volume_up_rounded,
                tooltip: _isMuted ? 'Unmute video' : 'Mute video',
                onTap: _toggleMute,
              ),
            ),
        ],
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({
    required this.icon,
    required this.onTap,
    required this.tooltip,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.black.withValues(alpha: 0.38),
        shape: CircleBorder(
          side: BorderSide(color: Colors.white.withValues(alpha: 0.14)),
        ),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
        ),
      ),
    );
  }
}
