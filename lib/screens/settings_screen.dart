import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/app_config.dart';
import '../providers/core_providers.dart';
import '../providers/library_providers.dart';
import '../providers/settings_provider.dart';
import '../services/ad_service.dart';
import '../services/fcm_service.dart';
import '../services/remote_config_service.dart';
import '../theme/app_colors.dart';
import '../widgets/app_update_dialog.dart';
import '../widgets/content_notice.dart';
import '../widgets/glass_container.dart';
import 'privacy_policy_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  void _openPrivacyPolicy(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const PrivacyPolicyScreen(),
      ),
    );
  }

  Future<void> _confirmClearHistory(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear play history?'),
        content: const Text(
          'This removes every game from Continue Playing. Favorites are kept.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    ref.read(recentlyPlayedProvider.notifier).clear();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Play history cleared')),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final historyCount = ref.watch(recentlyPlayedProvider).length;
    final version = ref.watch(packageInfoProvider).asData?.value;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return ListView(
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      padding: EdgeInsets.fromLTRB(
        16,
        MediaQuery.paddingOf(context).top + 16,
        16,
        bottomInset + 24,
      ),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text('Settings', style: theme.textTheme.headlineSmall),
        ),
        const _GroupLabel('Appearance'),
        _Group(
          children: [
            SwitchListTile(
              value: settings.darkMode,
              onChanged: notifier.setDarkMode,
              secondary: const _TileIcon(Icons.dark_mode_rounded),
              title: const Text('Dark mode'),
              subtitle: const Text('Easy on the eyes, made for gaming'),
            ),
          ],
        ),
        const _GroupLabel('Previews'),
        _Group(
          children: [
            SwitchListTile(
              value: settings.autoplayPreviews,
              onChanged: notifier.setAutoplayPreviews,
              secondary: const _TileIcon(Icons.play_circle_rounded),
              title: const Text('Autoplay previews'),
              subtitle: const Text('Play muted gameplay clips on game cards'),
            ),
            SwitchListTile(
              value: settings.wifiOnly,
              onChanged:
                  settings.autoplayPreviews ? notifier.setWifiOnly : null,
              secondary: const _TileIcon(Icons.wifi_rounded),
              title: const Text('Only on Wi-Fi'),
              subtitle: const Text('Save mobile data by skipping previews'),
            ),
          ],
        ),
        const _GroupLabel('Data'),
        _Group(
          children: [
            ListTile(
              leading: const _TileIcon(Icons.history_rounded),
              title: const Text('Clear play history'),
              subtitle: Text(
                historyCount == 0
                    ? 'Nothing to clear'
                    : '$historyCount recently played',
              ),
              enabled: historyCount > 0,
              onTap: () => _confirmClearHistory(context, ref),
            ),
          ],
        ),
        // const _GroupLabel('Notifications'),
        // _Group(
        //   children: [
        //     ListTile(
        //       leading: const _TileIcon(Icons.notifications_active_rounded),
        //       title: const Text('Test Notification'),
        //       subtitle: const Text('Send a test notification to status bar'),
        //       trailing: const Icon(Icons.send_rounded, size: 18),
        //       onTap: () async {
        //         await FcmService.instance.showTestNotification();
        //         if (!context.mounted) return;
        //         ScaffoldMessenger.of(context).showSnackBar(
        //           const SnackBar(
        //             content: Text('Test notification sent to your status bar!'),
        //             duration: Duration(seconds: 2),
        //           ),
        //         );
        //       },
        //     ),
        //     ListTile(
        //       leading: const _TileIcon(Icons.key_rounded),
        //       title: const Text('FCM Device Token'),
        //       subtitle: const Text('Tap to copy token for Firebase Console'),
        //       trailing: const Icon(Icons.copy_rounded, size: 18),
        //       onTap: () async {
        //         final token = FcmService.instance.fcmToken;
        //         if (token != null && token.isNotEmpty) {
        //           await Clipboard.setData(ClipboardData(text: token));
        //           if (!context.mounted) return;
        //           ScaffoldMessenger.of(context).showSnackBar(
        //             const SnackBar(
        //               content: Text('FCM Device Token copied to clipboard!'),
        //               duration: Duration(seconds: 3),
        //             ),
        //           );
        //         } else {
        //           ScaffoldMessenger.of(context).showSnackBar(
        //             const SnackBar(
        //               content:
        //                   Text('Fetching token... check internet connection.'),
        //             ),
        //           );
        //         }
        //       },
        //     ),
        //   ],
        // ),
        const _GroupLabel('About'),
        _Group(
          children: [
            ListTile(
              leading: const _TileIcon(Icons.privacy_tip_rounded),
              title: const Text('Privacy policy'),
              trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
              onTap: () => _openPrivacyPolicy(context),
            ),
            ListTile(
              leading: const _TileIcon(Icons.verified_user_rounded),
              title: const Text('Content notice'),
              subtitle: const Text('For ages ${AppConfig.minimumAge}+'),
              onTap: () => showContentNotice(context),
            ),
            if (AdService.instance.privacyOptionsRequired)
              ListTile(
                leading: const _TileIcon(Icons.tune_rounded),
                title: const Text('Ad privacy choices'),
                onTap: AdService.instance.showPrivacyOptions,
              ),
            ListTile(
              leading: const _TileIcon(Icons.system_update_rounded),
              title: const Text('Version'),
              subtitle: const Text('Tap to check for updates'),
              trailing: Text(
                version == null
                    ? ''
                    : '${version.version} (${version.buildNumber})',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              onTap: () async {
                final update =
                    await RemoteConfigService.instance.checkDeviceUpdate();
                if (!context.mounted) return;
                if (update.hasUpdate) {
                  await showDialog<void>(
                    context: context,
                    barrierDismissible: !update.isForceUpdate,
                    builder: (ctx) => AppUpdateDialog(info: update),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content:
                          Text('You are using the latest version of PlayHub!'),
                    ),
                  );
                }
              },
            ),
          ],
        ),
        const SizedBox(height: 20),
        GlassContainer(
          tint: AppColors.violet.withValues(alpha: 0.10),
          radius: 18,
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info_outline_rounded, color: AppColors.cyan),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  contentNoticeText,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _GroupLabel extends StatelessWidget {
  const _GroupLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 24, 6, 10),
      child: Text(
        label.toUpperCase(),
        style: theme.textTheme.labelMedium?.copyWith(
          letterSpacing: 1.4,
          fontWeight: FontWeight.w700,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
        ),
      ),
    );
  }
}

class _Group extends StatelessWidget {
  const _Group({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      radius: 20,
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Material(
        type: MaterialType.transparency,
        child: Column(
          children: [
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0) const Divider(height: 1, indent: 68, endIndent: 16),
              children[i],
            ],
          ],
        ),
      ),
    );
  }
}

class _TileIcon extends StatelessWidget {
  const _TileIcon(this.icon);

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(11),
      ),
      child: Icon(icon, color: Colors.white, size: 20),
    );
  }
}
