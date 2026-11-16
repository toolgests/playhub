import 'dart:async';
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../config/app_config.dart';
import '../../providers/catalog_providers.dart';
import '../../providers/network_provider.dart';
import '../../providers/notification_provider.dart';
import '../../theme/app_colors.dart';
import '../../utils/genre_style.dart';
import '../../utils/text_utils.dart';
import '../../widgets/app_logo.dart';
import '../../widgets/chips.dart';
import '../../widgets/common.dart';
import '../../widgets/paged_game_grid.dart';
import '../notifications_screen.dart';
import 'continue_playing_row.dart';
import 'external_games_row.dart';
import 'featured_carousel.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key, required this.scrollController});

  final ScrollController scrollController;

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final TextEditingController _search = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  final Debouncer _debouncer = Debouncer(const Duration(milliseconds: 300));

  @override
  void dispose() {
    _debouncer.dispose();
    _search.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    setState(() {});
    _debouncer.run(() {
      if (mounted) ref.read(homeFilterProvider.notifier).setQuery(value);
    });
  }

  void _clearQuery() {
    _search.clear();
    _debouncer.cancel();
    ref.read(homeFilterProvider.notifier).setQuery('');
    setState(() {});
  }

  void _clearFilters() {
    _search.clear();
    _debouncer.cancel();
    ref.read(homeFilterProvider.notifier).clear();
    setState(() {});
  }

  void _selectGenre(String? genre) {
    ref.read(homeFilterProvider.notifier).setGenre(genre);
    final controller = widget.scrollController;
    if (controller.hasClients && controller.offset > 0) {
      controller.jumpTo(0);
    }
  }

  Future<void> _focusSearch() async {
    final controller = widget.scrollController;
    if (controller.hasClients && controller.offset > 0) {
      await controller.animateTo(
        0,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    }
    if (mounted) _searchFocus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filter = ref.watch(homeFilterProvider);
    final games = ref.watch(homeGamesProvider);
    final catalog = ref.watch(catalogDataProvider);
    final catalogAsync = ref.watch(catalogProvider);
    final genres = ref.watch(homeGenresProvider);
    final featured = ref.watch(featuredGamesProvider);
    final externalGames = ref.watch(externalGamesProvider);
    final online = ref.watch(isOnlineProvider);
    final showRails = filter.isDefault;

    final String sectionTitle;
    if (showRails) {
      sectionTitle = 'All games';
    } else if (filter.query.trim().isNotEmpty) {
      sectionTitle = 'Results for "${filter.query.trim()}"';
    } else {
      sectionTitle = genreLabel(filter.genre ?? '');
    }

    return PagedGameScrollView(
      controller: widget.scrollController,
      games: games,
      section: 'home',
      onRefresh: () async {
        ref.invalidate(catalogProvider);
        await ref.read(catalogProvider.future);
      },
      headerSlivers: [
        // 1. Sliding Top App Bar (slides out of view when scrolling)
        SliverAppBar(
          pinned: false,
          floating: false,
          automaticallyImplyLeading: false,
          toolbarHeight: 58,
          titleSpacing: 16,
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          title: Row(
            children: [
              const AppLogo(size: 34, glow: false),
              const SizedBox(width: 10),
              Text(
                AppConfig.appName,
                style: GoogleFonts.orbitron(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          actions: [
            if (!filter.isDefault)
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: TextButton.icon(
                  onPressed: _clearFilters,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Reset'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.pink,
                  ),
                ),
              )
            else
              IconButton(
                tooltip: 'Search',
                onPressed: _focusSearch,
                icon: const Icon(Icons.search_rounded),
              ),
            const _NotificationIconButton(),
            const SizedBox(width: 6),
          ],
        ),

        // 2. Sticky Search Bar and Category Tabs (stays stuck at the top)
        SliverAppBar(
          pinned: true,
          floating: false,
          automaticallyImplyLeading: false,
          toolbarHeight: 124,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(20),
            ),
            // side: BorderSide(
            //   color: Color(0xFF2A2A2A),
            //   width: 0.8,
            // ),
          ),
          titleSpacing: 0,
          backgroundColor:
              theme.scaffoldBackgroundColor.withValues(alpha: 0.99),
          surfaceTintColor: Colors.transparent,
          flexibleSpace: const _FrostedBar(),
          title: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _SearchField(
                  controller: _search,
                  focusNode: _searchFocus,
                  onChanged: _onQueryChanged,
                  onClear: _clearQuery,
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 50,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.only(
                      left: 16, right: 16, top: 0, bottom: 10),
                  itemCount: genres.length + 1,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return GradientChip(
                        label: 'All',
                        icon: Icons.apps_rounded,
                        selected: filter.genre == null,
                        onTap: () => _selectGenre(null),
                      );
                    }
                    final genre = genres[index - 1].genre;
                    final selected = filter.genre == genre;
                    return GradientChip(
                      label: genreLabel(genre),
                      icon: genreIcon(genre),
                      selected: selected,
                      onTap: () => _selectGenre(selected ? null : genre),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
        if (!online)
          SliverToBoxAdapter(
            child: OfflineBanner(
              onRetry: () => ref.invalidate(networkStatusProvider),
            ),
          ),
        if (showRails && featured.isNotEmpty)
          SliverToBoxAdapter(child: FeaturedCarousel(games: featured)),
        if (showRails && externalGames.isVisible)
          SliverToBoxAdapter(
            child: ExternalGamesRow(
              heading: externalGames.heading,
              games: externalGames.games,
            ),
          ),
        if (showRails) const SliverToBoxAdapter(child: ContinuePlayingRow()),
        if (games.isNotEmpty)
          SliverToBoxAdapter(
            child: SectionHeader(
              title: sectionTitle,
              trailing: showRails ? '${games.length} games' : 'Clear',
              onTrailingTap: showRails ? null : _clearFilters,
            ),
          ),
      ],
      emptyState: catalogAsync.isLoading && catalog.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 60, horizontal: 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 36,
                      height: 36,
                      child: CircularProgressIndicator(strokeWidth: 3),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Loading live games...',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),
              ),
            )
          : catalog.isEmpty
              ? EmptyState(
                  icon: Icons.cloud_off_rounded,
                  title: 'Unable to load games',
                  message: 'Check your internet connection or try again.',
                  actionLabel: 'Retry',
                  onAction: () => ref.invalidate(catalogProvider),
                )
              : EmptyState(
                  icon: Icons.search_off_rounded,
                  title: 'No games found',
                  message: 'Try a different name or pick another category.',
                  actionLabel: 'Clear filters',
                  onAction: _clearFilters,
                ),
    );
  }
}

class _FrostedBar extends StatelessWidget {
  const _FrostedBar();

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: ColoredBox(
          color: dark
              ? AppColors.bgTop.withValues(alpha: 0.88)
              : AppColors.lightBgTop.withValues(alpha: 0.88),
        ),
      ),
    );
  }
}

class _SearchField extends StatefulWidget {
  const _SearchField({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  State<_SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<_SearchField> {
  static const List<String> _hintSuggestions = [
    'Search "Piece of Cake"...',
    'Search "Puzzle games"...',
    'Search "Arcade"...',
    'Search "Action"...',
    'Search "Racing games"...',
    'Search "3D games"...',
    'Search "Cooking City"...',
    'Search "Adventure"...',
    'Search "Multiplayer"...',
    'Search "Merge"...',
  ];

  int _hintIndex = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startHintTimer();
    widget.controller.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    if (mounted) setState(() {});
  }

  void _startHintTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 2600), (_) {
      if (!mounted) return;
      if (widget.controller.text.isEmpty) {
        setState(() {
          _hintIndex = (_hintIndex + 1) % _hintSuggestions.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final radius = BorderRadius.circular(16);
    final isFieldEmpty = widget.controller.text.isEmpty;

    return SizedBox(
      height: 48,
      child: Stack(
        alignment: Alignment.centerLeft,
        children: [
          TextField(
            controller: widget.controller,
            focusNode: widget.focusNode,
            onChanged: widget.onChanged,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => widget.focusNode.unfocus(),
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              prefixIcon: Icon(
                Icons.search_rounded,
                color: onSurface.withValues(alpha: 0.6),
                size: 22,
              ),
              suffixIcon: isFieldEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Clear search',
                      onPressed: widget.onClear,
                      icon: const Icon(Icons.close_rounded, size: 20),
                    ),
              filled: true,
              fillColor: onSurface.withValues(alpha: 0.07),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              border: OutlineInputBorder(
                borderRadius: radius,
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: radius,
                borderSide:
                    BorderSide(color: onSurface.withValues(alpha: 0.08)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: radius,
                borderSide:
                    const BorderSide(color: AppColors.violet, width: 1.4),
              ),
            ),
          ),
          if (isFieldEmpty)
            Positioned(
              left: 48,
              right: 48,
              child: IgnorePointer(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 380),
                  transitionBuilder: (child, animation) {
                    final slideIn = Tween<Offset>(
                      begin: const Offset(0.0, 0.7),
                      end: Offset.zero,
                    ).animate(
                      CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeOutCubic,
                      ),
                    );
                    return ClipRect(
                      child: SlideTransition(
                        position: slideIn,
                        child: FadeTransition(
                          opacity: animation,
                          child: child,
                        ),
                      ),
                    );
                  },
                  child: Text(
                    _hintSuggestions[_hintIndex],
                    key: ValueKey<int>(_hintIndex),
                    textAlign: TextAlign.start,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: onSurface.withValues(alpha: 0.45),
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _NotificationIconButton extends ConsumerWidget {
  const _NotificationIconButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadCount = ref.watch(unreadNotificationsCountProvider);

    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        IconButton(
          tooltip: 'Notifications',
          icon: const Icon(Icons.notifications_none_rounded, size: 24),
          onPressed: () {
            Navigator.of(context).push<void>(
              MaterialPageRoute<void>(
                builder: (_) => const NotificationsScreen(),
              ),
            );
          },
        ),
        if (unreadCount > 0)
          Positioned(
            top: 7,
            right: 7,
            child: IgnorePointer(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                constraints: const BoxConstraints(
                  minWidth: 17,
                  minHeight: 17,
                ),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.pink.withValues(alpha: 0.6),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Text(
                  unreadCount > 9 ? '9+' : '$unreadCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    height: 1,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
