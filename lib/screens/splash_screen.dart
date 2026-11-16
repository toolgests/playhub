import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_config.dart';
import '../models/catalog.dart';
import '../providers/catalog_providers.dart';
import '../theme/app_colors.dart';
import '../widgets/app_logo.dart';
import '../widgets/gradient_background.dart';
import '../widgets/gradient_button.dart';
import 'shell_screen.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  final Future<void> _minimumDisplay =
      Future<void>.delayed(const Duration(milliseconds: 1600));
  bool _leaving = false;

  @override
  void initState() {
    super.initState();
    ref.listenManual<AsyncValue<Catalog>>(
      catalogProvider,
      (_, next) {
        if (next.hasValue) _goHome();
      },
      fireImmediately: true,
    );
  }

  Future<void> _goHome() async {
    if (_leaving) return;
    _leaving = true;
    await _minimumDisplay;
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (_, __, ___) => const ShellScreen(),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final catalog = ref.watch(catalogProvider);
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.7);

    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          child: SizedBox(
            width: double.infinity,
            child: Column(
              children: [
                const Spacer(flex: 3),
                const AppLogo(size: 104)
                    .animate()
                    .scale(
                      begin: const Offset(0.6, 0.6),
                      end: const Offset(1, 1),
                      duration: 700.ms,
                      curve: Curves.easeOutBack,
                    )
                    .fadeIn(duration: 400.ms)
                    .then(delay: 150.ms)
                    .shimmer(
                      duration: 1200.ms,
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                const SizedBox(height: 28),
                Text(
                  AppConfig.appName,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                )
                    .animate(delay: 250.ms)
                    .fadeIn(duration: 500.ms)
                    .moveY(begin: 12, end: 0),
                const SizedBox(height: 8),
                Text(
                  AppConfig.tagline,
                  style: theme.textTheme.bodyMedium?.copyWith(color: muted),
                ).animate(delay: 450.ms).fadeIn(duration: 500.ms),
                const Spacer(flex: 2),
                if (catalog.hasError && !catalog.hasValue)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Column(
                      children: [
                        Text(
                          'We could not load the game catalog.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 16),
                        GradientButton(
                          label: 'Try again',
                          icon: Icons.refresh_rounded,
                          height: 48,
                          onPressed: () => ref.invalidate(catalogProvider),
                        ),
                      ],
                    ),
                  )
                else
                  const _LoadingDots(),
                const SizedBox(height: 56),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LoadingDots extends StatelessWidget {
  const _LoadingDots();

  static const _colors = [AppColors.violet, AppColors.pink, AppColors.cyan];

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < _colors.length; i++)
          Container(
            width: 9,
            height: 9,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: _colors[i],
              shape: BoxShape.circle,
            ),
          )
              .animate(
                delay: (i * 160).ms,
                onPlay: (c) => c.repeat(reverse: true),
              )
              .scaleXY(begin: 0.6, end: 1.2, duration: 500.ms)
              .fade(begin: 0.4, end: 1, duration: 500.ms),
      ],
    );
  }
}
