import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Skeleton placeholder with a moving highlight.
class ShimmerBox extends StatelessWidget {
  const ShimmerBox({super.key, this.borderRadius = BorderRadius.zero});

  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox.expand(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: dark ? const Color(0xFF241B47) : const Color(0xFFE4DDFB),
          borderRadius: borderRadius,
        ),
      ),
    )
        .animate(onPlay: (controller) => controller.repeat())
        .shimmer(
          duration: 1200.ms,
          color: Colors.white.withValues(alpha: dark ? 0.08 : 0.55),
        );
  }
}
