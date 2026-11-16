import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'shimmer_box.dart';

/// Cached network image that decodes at its on-screen pixel width,
/// with a shimmer placeholder and a branded fallback.
class GameImage extends StatelessWidget {
  const GameImage({super.key, required this.url, this.fit = BoxFit.cover});

  final String? url;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final imageUrl = url;
    if (imageUrl == null || imageUrl.isEmpty) return const ImageFallback();

    return LayoutBuilder(
      builder: (context, constraints) {
        final dpr = MediaQuery.devicePixelRatioOf(context);
        final cacheWidth = constraints.maxWidth.isFinite
            ? (constraints.maxWidth * dpr).round()
            : null;
        return CachedNetworkImage(
          imageUrl: imageUrl,
          fit: fit,
          memCacheWidth: cacheWidth,
          fadeInDuration: const Duration(milliseconds: 250),
          fadeOutDuration: const Duration(milliseconds: 120),
          placeholder: (context, _) => const ShimmerBox(),
          errorWidget: (context, _, __) => const ImageFallback(),
        );
      },
    );
  }
}

class ImageFallback extends StatelessWidget {
  const ImageFallback({super.key});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.violet.withValues(alpha: 0.55),
            AppColors.pink.withValues(alpha: 0.45),
          ],
        ),
      ),
      child: const Center(
        child: Icon(
          Icons.sports_esports_rounded,
          color: Colors.white70,
          size: 36,
        ),
      ),
    );
  }
}
