import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 88, this.glow = true});

  final double size;
  final bool glow;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(size * 0.3),
        boxShadow: glow
            ? [
                BoxShadow(
                  color: AppColors.violet.withValues(alpha: 0.5),
                  blurRadius: size * 0.4,
                  offset: Offset(0, size * 0.1),
                ),
              ]
            : null,
      ),
      child: Icon(
        Icons.sports_esports_rounded,
        color: Colors.white,
        size: size * 0.56,
      ),
    );
  }
}
