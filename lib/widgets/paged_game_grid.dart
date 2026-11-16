import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../config/app_config.dart';
import '../models/game.dart';
import 'game_card.dart';

/// Scroll view with optional header slivers and a lazily growing game grid.
///
/// Builds [AppConfig.pageSize] cards at a time and adds the next page as
/// the user nears the end. A new [games] list resets paging.
class PagedGameScrollView extends StatefulWidget {
  const PagedGameScrollView({
    super.key,
    required this.games,
    required this.section,
    this.headerSlivers = const <Widget>[],
    this.controller,
    this.emptyState,
    this.onRefresh,
  });

  final List<Game> games;
  final String section;
  final List<Widget> headerSlivers;
  final ScrollController? controller;
  final Widget? emptyState;
  final Future<void> Function()? onRefresh;

  @override
  State<PagedGameScrollView> createState() => _PagedGameScrollViewState();
}

class _PagedGameScrollViewState extends State<PagedGameScrollView> {
  static const double _horizontalPadding = 16;
  static const double _crossSpacing = 12;
  static const double _mainSpacing = 16;
  static const double _loadAheadPx = 900;

  ScrollController? _ownController;
  int _visible = AppConfig.pageSize;

  ScrollController get _controller =>
      widget.controller ?? (_ownController ??= ScrollController());

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onScroll);
    _scheduleFillCheck();
  }

  @override
  void didUpdateWidget(covariant PagedGameScrollView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      (oldWidget.controller ?? _ownController)?.removeListener(_onScroll);
      _controller.addListener(_onScroll);
    }
    if (!identical(oldWidget.games, widget.games)) {
      _visible = AppConfig.pageSize;
      _scheduleFillCheck();
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onScroll);
    _ownController?.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_controller.hasClients) return;
    final position = _controller.position;
    if (position.pixels >= position.maxScrollExtent - _loadAheadPx) {
      _loadMore();
    }
  }

  void _loadMore() {
    final total = widget.games.length;
    if (_visible >= total) return;
    setState(() => _visible = math.min(_visible + AppConfig.pageSize, total));
    _scheduleFillCheck();
  }

  /// On tall screens the first page may not fill the viewport, so no scroll
  /// event would ever load the next one.
  void _scheduleFillCheck() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_controller.hasClients) return;
      final position = _controller.position;
      if (position.maxScrollExtent - position.pixels < _loadAheadPx) {
        _loadMore();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final games = widget.games;
    final width = MediaQuery.sizeOf(context).width;
    final columns = width >= 600 ? 3 : 2;
    final itemWidth = (width -
            _horizontalPadding * 2 -
            _crossSpacing * (columns - 1)) /
        columns;
    final extent = GameCard.extentFor(itemWidth, MediaQuery.textScalerOf(context));
    final count = math.min(_visible, games.length);
    final hasMore = count < games.length;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final emptyState = widget.emptyState;

    final scrollView = CustomScrollView(
      controller: _controller,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      cacheExtent: 600,
      slivers: [
        ...widget.headerSlivers,
        if (games.isEmpty && emptyState != null)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Padding(
              padding: EdgeInsets.only(bottom: bottomInset),
              child: emptyState,
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: _horizontalPadding),
            sliver: SliverGrid.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                mainAxisSpacing: _mainSpacing,
                crossAxisSpacing: _crossSpacing,
                mainAxisExtent: extent,
              ),
              itemCount: count,
              itemBuilder: (context, index) {
                final game = games[index];
                return GameCard(
                  key: ValueKey<String>(game.id),
                  game: game,
                  section: widget.section,
                );
              },
            ),
          ),
        if (hasMore)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: SizedBox(
                  width: 26,
                  height: 26,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                ),
              ),
            ),
          ),
        SliverPadding(padding: EdgeInsets.only(bottom: bottomInset + 24)),
      ],
    );

    if (widget.onRefresh != null) {
      return RefreshIndicator(
        color: Colors.white,
        backgroundColor: const Color(0xFF1C1438),
        onRefresh: widget.onRefresh!,
        child: scrollView,
      );
    }

    return scrollView;
  }
}
