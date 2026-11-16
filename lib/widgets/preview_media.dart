import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../data/video_url_resolver.dart';
import '../models/game.dart';
import '../providers/preview_video_provider.dart';
import '../services/preview_video_manager.dart';
import 'game_image.dart';

/// A game's preview image that cross-fades into a muted, looping gameplay
/// clip when the shared [PreviewVideoManager] grants this slot a player.
class PreviewMedia extends ConsumerStatefulWidget {
  const PreviewMedia({
    super.key,
    required this.game,
    required this.slotKey,
    this.priority = 0,
    this.heroTag,
  });

  final Game game;

  /// Unique per on-screen placement (section plus game id).
  final String slotKey;

  /// Higher wins a player first: detail 2, featured 1, grid 0.
  final int priority;
  final Object? heroTag;

  @override
  ConsumerState<PreviewMedia> createState() => _PreviewMediaState();
}

class _PreviewMediaState extends ConsumerState<PreviewMedia> {
  late final PreviewVideoManager _manager;
  String? _videoUrl;

  @override
  void initState() {
    super.initState();
    _manager = ref.read(previewVideoManagerProvider);
    _videoUrl = resolveVideoUrl(widget.game);
  }

  @override
  void didUpdateWidget(covariant PreviewMedia oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.slotKey != widget.slotKey) {
      _manager.unregister(oldWidget.slotKey);
    }
    if (oldWidget.game.id != widget.game.id) {
      _videoUrl = resolveVideoUrl(widget.game);
    }
  }

  @override
  void dispose() {
    _manager.unregister(widget.slotKey);
    super.dispose();
  }

  void _onVisibilityChanged(VisibilityInfo info) {
    if (!mounted) return;
    _manager.report(
      widget.slotKey,
      _videoUrl,
      info.visibleFraction,
      priority: widget.priority,
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget image = GameImage(url: widget.game.previewImage);
    final heroTag = widget.heroTag;
    if (heroTag != null) image = Hero(tag: heroTag, child: image);

    if (_videoUrl == null) return image;

    return VisibilityDetector(
      key: ValueKey<String>('preview_${widget.slotKey}'),
      onVisibilityChanged: _onVisibilityChanged,
      child: Stack(
        fit: StackFit.expand,
        children: [
          image,
          ListenableBuilder(
            listenable: _manager,
            builder: (context, _) {
              final controller = _manager.controllerFor(widget.slotKey);
              if (controller == null) return const SizedBox.shrink();
              return _VideoLayer(
                key: ObjectKey(controller),
                controller: controller,
              );
            },
          ),
        ],
      ),
    );
  }
}

class _VideoLayer extends StatelessWidget {
  const _VideoLayer({super.key, required this.controller});

  final VideoPlayerController controller;

  @override
  Widget build(BuildContext context) {
    final size = controller.value.size;
    final width = size.width > 0 ? size.width : 16.0;
    final height = size.height > 0 ? size.height : 9.0;

    return IgnorePointer(
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: 1),
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOut,
        builder: (context, opacity, child) =>
            Opacity(opacity: opacity, child: child),
        child: ClipRect(
          child: FittedBox(
            fit: BoxFit.cover,
            clipBehavior: Clip.hardEdge,
            child: SizedBox(
              width: width,
              height: height,
              child: VideoPlayer(controller),
            ),
          ),
        ),
      ),
    );
  }
}
