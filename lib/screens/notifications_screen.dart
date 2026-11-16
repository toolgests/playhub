import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/notification_item.dart';
import '../providers/catalog_providers.dart';
import '../providers/notification_provider.dart';
import '../services/game_navigation.dart';
import '../theme/app_colors.dart';
import '../widgets/chips.dart';
import '../widgets/common.dart';
import '../widgets/game_image.dart';
import '../widgets/glass_container.dart';
import '../widgets/gradient_background.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  String _selectedFilter = 'all';

  String _formatTimeAgo(DateTime timestamp) {
    final diff = DateTime.now().difference(timestamp);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
  }

  void _onNotificationTap(NotificationItem item) {
    if (!item.isRead) {
      ref.read(notificationsProvider.notifier).markAsRead(item.id);
    }

    if (item.gameId != null) {
      final catalog = ref.read(catalogDataProvider);
      final game = catalog.byId[item.gameId];
      if (game != null) {
        openGameDetail(context, game);
      }
    }
  }

  Future<void> _confirmClearAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1C1438),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Clear all notifications?',
          style: GoogleFonts.orbitron(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        content: const Text(
          'This will remove all notifications from your list.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Clear All', style: TextStyle(color: AppColors.pink)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      ref.read(notificationsProvider.notifier).clearAll();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All notifications cleared')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final notifications = ref.watch(notificationsProvider);
    final unreadCount = ref.watch(unreadNotificationsCountProvider);

    final filteredList = notifications.where((item) {
      switch (_selectedFilter) {
        case 'unread':
          return !item.isRead;
        case 'games':
          return item.type == NotificationType.game;
        case 'rewards':
          return item.type == NotificationType.reward;
        case 'tournaments':
          return item.type == NotificationType.tournament;
        default:
          return true;
      }
    }).toList();

    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              // Custom Top App Bar
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 12, 12),
                child: Row(
                  children: [
                    IconButton(
                      tooltip: 'Back',
                      icon: const Icon(Icons.arrow_back_rounded),
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'NOTIFICATIONS',
                        style: GoogleFonts.orbitron(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                    if (unreadCount > 0)
                      IconButton(
                        tooltip: 'Mark all as read',
                        icon: const Icon(Icons.done_all_rounded),
                        onPressed: () {
                          ref.read(notificationsProvider.notifier).markAllAsRead();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('All marked as read'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                      ),
                    if (notifications.isNotEmpty)
                      IconButton(
                        tooltip: 'Clear all',
                        icon: const Icon(Icons.delete_sweep_rounded),
                        onPressed: _confirmClearAll,
                      ),
                  ],
                ),
              ),

              // Filter Chips
              if (notifications.isNotEmpty)
                SizedBox(
                  height: 42,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      GradientChip(
                        label: 'All (${notifications.length})',
                        icon: Icons.list_alt_rounded,
                        selected: _selectedFilter == 'all',
                        onTap: () => setState(() => _selectedFilter = 'all'),
                      ),
                      const SizedBox(width: 8),
                      GradientChip(
                        label: 'Unread ($unreadCount)',
                        icon: Icons.mark_email_unread_rounded,
                        selected: _selectedFilter == 'unread',
                        onTap: () => setState(() => _selectedFilter = 'unread'),
                      ),
                      const SizedBox(width: 8),
                      GradientChip(
                        label: 'Games',
                        icon: Icons.sports_esports_rounded,
                        selected: _selectedFilter == 'games',
                        onTap: () => setState(() => _selectedFilter = 'games'),
                      ),
                      const SizedBox(width: 8),
                      GradientChip(
                        label: 'Rewards',
                        icon: Icons.bolt_rounded,
                        selected: _selectedFilter == 'rewards',
                        onTap: () => setState(() => _selectedFilter = 'rewards'),
                      ),
                      const SizedBox(width: 8),
                      GradientChip(
                        label: 'Tournaments',
                        icon: Icons.emoji_events_rounded,
                        selected: _selectedFilter == 'tournaments',
                        onTap: () =>
                            setState(() => _selectedFilter = 'tournaments'),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 10),

              // Notification List
              Expanded(
                child: RefreshIndicator(
                  color: AppColors.pink,
                  backgroundColor: const Color(0xFF1C1438),
                  onRefresh: () =>
                      ref.read(notificationsProvider.notifier).refresh(),
                  child: filteredList.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(
                            parent: BouncingScrollPhysics(),
                          ),
                          children: [
                            SizedBox(
                              height: MediaQuery.sizeOf(context).height * 0.5,
                              child: Center(
                                child: EmptyState(
                                  icon: Icons.notifications_off_rounded,
                                  title: _selectedFilter == 'all'
                                      ? 'No notifications'
                                      : 'No $_selectedFilter notifications',
                                  message: _selectedFilter == 'all'
                                      ? 'You are all caught up! Check back later for new game releases and bonuses.'
                                      : 'There are currently no items under this category.',
                                ),
                              ),
                            ),
                          ],
                        )
                      : ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(
                            parent: BouncingScrollPhysics(),
                          ),
                          padding: EdgeInsets.fromLTRB(
                            16,
                            8,
                            16,
                            MediaQuery.paddingOf(context).bottom + 24,
                          ),
                          itemCount: filteredList.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final item = filteredList[index];
                            return _NotificationCard(
                              key: ValueKey(item.id),
                              item: item,
                              timeAgo: _formatTimeAgo(item.timestamp),
                              onTap: () => _onNotificationTap(item),
                              onDismiss: () {
                                ref
                                    .read(notificationsProvider.notifier)
                                    .deleteNotification(item.id);
                              },
                            )
                                .animate()
                                .fadeIn(
                                    duration: 250.ms, delay: (index * 40).ms)
                                .moveY(begin: 10, end: 0);
                          },
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    super.key,
    required this.item,
    required this.timeAgo,
    required this.onTap,
    required this.onDismiss,
  });

  final NotificationItem item;
  final String timeAgo;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  IconData _iconForType(NotificationType type) {
    switch (type) {
      case NotificationType.game:
        return Icons.sports_esports_rounded;
      case NotificationType.reward:
        return Icons.bolt_rounded;
      case NotificationType.tournament:
        return Icons.emoji_events_rounded;
      case NotificationType.system:
        return Icons.campaign_rounded;
    }
  }

  Gradient _gradientForType(NotificationType type) {
    switch (type) {
      case NotificationType.game:
        return AppColors.primaryGradient;
      case NotificationType.reward:
        return const LinearGradient(
          colors: [Color(0xFFFF9800), Color(0xFFFF5722)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case NotificationType.tournament:
        return const LinearGradient(
          colors: [Color(0xFFFFD700), Color(0xFFFFA000)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case NotificationType.system:
        return const LinearGradient(
          colors: [AppColors.cyan, AppColors.violet],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final onSurface = theme.colorScheme.onSurface;

    return Dismissible(
      key: ValueKey(item.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDismiss(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.redAccent.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
      ),
      child: GestureDetector(
        onTap: onTap,
        child: GlassContainer(
          radius: 20,
          tint: !item.isRead
              ? (dark
                  ? AppColors.violet.withValues(alpha: 0.16)
                  : AppColors.violet.withValues(alpha: 0.08))
              : null,
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon Badge
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: _gradientForType(item.type),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.violet.withValues(alpha: 0.28),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  _iconForType(item.type),
                  color: Colors.white,
                  size: 24,
                ),
              ),

              const SizedBox(width: 12),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight:
                                  item.isRead ? FontWeight.w600 : FontWeight.w800,
                              color: onSurface,
                            ),
                          ),
                        ),
                        if (!item.isRead) ...[
                          const SizedBox(width: 6),
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: AppColors.primaryGradient,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      item.message,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: onSurface.withValues(alpha: item.isRead ? 0.65 : 0.85),
                        height: 1.4,
                      ),
                    ),
                    if (item.imageUrl != null &&
                        item.imageUrl!.startsWith('http')) ...[
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: SizedBox(
                          height: 100,
                          width: double.infinity,
                          child: GameImage(url: item.imageUrl),
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          timeAgo,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: onSurface.withValues(alpha: 0.45),
                            fontSize: 11,
                          ),
                        ),
                        if (item.gameId != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              gradient: AppColors.primaryGradient,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'PLAY',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.6,
                                  ),
                                ),
                                SizedBox(width: 3),
                                Icon(
                                  Icons.play_arrow_rounded,
                                  color: Colors.white,
                                  size: 13,
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

