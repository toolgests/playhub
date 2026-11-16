import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/library_providers.dart';
import '../theme/app_colors.dart';

/// Heart toggle that pops with an elastic scale when it changes.
class FavoriteHeart extends ConsumerWidget {
  const FavoriteHeart({super.key, required this.gameId, this.size = 18});

  final String gameId;
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFavorite =
        ref.watch(favoritesProvider.select((ids) => ids.contains(gameId)));

    return Semantics(
      button: true,
      toggled: isFavorite,
      label: isFavorite ? 'Remove from favorites' : 'Add to favorites',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          HapticFeedback.lightImpact();
          ref.read(favoritesProvider.notifier).toggle(gameId);
        },
        child: Container(
          padding: EdgeInsets.all(size * 0.38),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.black.withValues(alpha: 0.38),
            border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 450),
            switchInCurve: Curves.elasticOut,
            switchOutCurve: Curves.easeIn,
            transitionBuilder: (child, animation) =>
                ScaleTransition(scale: animation, child: child),
            child: Icon(
              isFavorite
                  ? Icons.favorite_rounded
                  : Icons.favorite_border_rounded,
              key: ValueKey<bool>(isFavorite),
              color: isFavorite ? AppColors.pink : Colors.white,
              size: size,
            ),
          ),
        ),
      ),
    );
  }
}
