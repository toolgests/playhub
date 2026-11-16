import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/ad_config.dart';
import '../providers/navigation_provider.dart';
import '../providers/settings_provider.dart';
import '../services/ad_service.dart';
import '../widgets/app_update_dialog.dart';
import '../widgets/banner_ad_slot.dart';
import '../widgets/content_notice.dart';
import '../widgets/floating_nav_bar.dart';
import '../widgets/gradient_background.dart';
import 'categories_screen.dart';
import 'favorites_screen.dart';
import 'home/home_screen.dart';
import 'settings_screen.dart';

/// Hosts the four tabs under one floating navigation bar.
class ShellScreen extends ConsumerStatefulWidget {
  const ShellScreen({super.key});

  @override
  ConsumerState<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends ConsumerState<ShellScreen> {
  final ScrollController _homeScroll = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startup());
  }

  @override
  void dispose() {
    _homeScroll.dispose();
    super.dispose();
  }

  Future<void> _startup() async {
    if (!ref.read(settingsProvider).noticeAccepted) {
      await showContentNotice(context, firstRun: true);
      if (!mounted) return;
      ref.read(settingsProvider.notifier).setNoticeAccepted(true);
    }
    await AdService.instance.initialize();
    if (!mounted) return;
    await checkAndShowAppUpdate(context);
  }

  void _onTabSelected(int index) {
    final current = ref.read(shellTabProvider);
    if (index == current && index == 0 && _homeScroll.hasClients) {
      _homeScroll.animateTo(
        0,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic,
      );
      return;
    }
    ref.read(shellTabProvider.notifier).select(index);
  }

  @override
  Widget build(BuildContext context) {
    final index = ref.watch(shellTabProvider);

    return PopScope(
      canPop: index == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) ref.read(shellTabProvider.notifier).select(0);
      },
      child: Scaffold(
        extendBody: true,
        body: GradientBackground(
          child: IndexedStack(
            index: index,
            children: [
              HomeScreen(scrollController: _homeScroll),
              const CategoriesScreen(),
              const FavoritesScreen(),
              const SettingsScreen(),
            ],
          ),
        ),
        bottomNavigationBar: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Offstage(
              offstage: index != 0,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: BannerAdSlot(adUnitId: AdConfig.homeBannerId),
              ),
            ),
            FloatingNavBar(currentIndex: index, onSelected: _onTabSelected),
          ],
        ),
      ),
    );
  }
}
