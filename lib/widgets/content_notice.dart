import 'package:flutter/material.dart';

import '../config/app_config.dart';
import '../theme/app_colors.dart';
import 'glass_container.dart';
import 'gradient_button.dart';

const String contentNoticeText =
    'Games in ${AppConfig.appName} are made by independent developers and '
    'load from the web, so you need an internet connection to play. Some '
    'games show their own ads or offer optional in-game purchases. '
    '${AppConfig.appName} is intended for players aged ${AppConfig.minimumAge} '
    'and over.';

/// Content and age notice. On first run it must be acknowledged.
Future<void> showContentNotice(
  BuildContext context, {
  bool firstRun = false,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: !firstRun,
    builder: (context) {
      final theme = Theme.of(context);
      return PopScope(
        canPop: !firstRun,
        child: Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: GlassContainer(
            blur: true,
            radius: 28,
            tint: theme.colorScheme.surface.withValues(alpha: 0.94),
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    gradient: AppColors.coolGradient,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.verified_user_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  firstRun ? 'Before you play' : 'Content notice',
                  style: theme.textTheme.titleLarge,
                ),
                const SizedBox(height: 10),
                Text(
                  contentNoticeText,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 22),
                GradientButton(
                  label: firstRun ? 'I understand' : 'Got it',
                  height: 50,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
