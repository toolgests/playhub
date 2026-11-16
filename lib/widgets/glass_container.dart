import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Semi-transparent surface with a hairline border. With [blur] it also
/// frosts whatever is behind it; keep that for a few large surfaces only.
class GlassContainer extends StatelessWidget {
  const GlassContainer({
    super.key,
    required this.child,
    this.padding = EdgeInsets.zero,
    this.radius = 20,
    this.blur = false,
    this.tint,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final bool blur;
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final borderRadius = BorderRadius.circular(radius);

    final box = DecoratedBox(
      decoration: BoxDecoration(
        color: tint ??
            (dark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.white.withValues(alpha: 0.75)),
        borderRadius: borderRadius,
        border: Border.all(
          color: dark
              ? Colors.white.withValues(alpha: 0.09)
              : AppColors.violet.withValues(alpha: 0.10),
        ),
      ),
      child: Padding(padding: padding, child: child),
    );

    if (!blur) return box;
    return ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: box,
      ),
    );
  }
}
