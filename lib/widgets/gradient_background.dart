import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Full-bleed navy/purple gradient with two soft glow blobs.
class GradientBackground extends StatelessWidget {
  const GradientBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: dark ? AppColors.backgroundDark : AppColors.backgroundLight,
      ),
      child: Stack(
        children: [
          Positioned(
            top: -140,
            right: -100,
            child: _GlowBlob(
              color: AppColors.violet.withValues(alpha: dark ? 0.28 : 0.16),
              size: 320,
            ),
          ),
          Positioned(
            bottom: -160,
            left: -120,
            child: _GlowBlob(
              color: AppColors.pink.withValues(alpha: dark ? 0.14 : 0.10),
              size: 340,
            ),
          ),
          Positioned.fill(child: child),
        ],
      ),
    );
  }
}

class _GlowBlob extends StatelessWidget {
  const _GlowBlob({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: RepaintBoundary(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [color, color.withValues(alpha: 0)],
            ),
          ),
        ),
      ),
    );
  }
}
