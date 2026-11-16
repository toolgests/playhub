import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

import '../models/game.dart';
import '../providers/network_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/game_image.dart';
import '../widgets/gradient_background.dart';
import '../widgets/gradient_button.dart';

/// Full-screen WebView player. Loads [Game.gameUrl] exactly as stored.
/// No ads are ever shown on this screen.
class PlayerScreen extends ConsumerStatefulWidget {
  const PlayerScreen({super.key, required this.game});

  final Game game;

  @override
  ConsumerState<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends ConsumerState<PlayerScreen> {
  static const Set<String> _inWebViewSchemes = {
    'http',
    'https',
    'about',
    'data',
    'blob',
    'javascript',
  };

  late final WebViewController _controller;
  int _progress = 0;
  bool _loading = true;
  String? _error;
  bool _systemUiRestored = false;
  Offset _closeOffset = const Offset(12, 12);

  @override
  void initState() {
    super.initState();
    _enterGameMode();
    _controller = _createController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _restoreSystemUi();
    super.dispose();
  }

  void _enterGameMode() {
    final game = widget.game;
    final List<DeviceOrientation> orientations;
    if (game.landscapeOnly) {
      orientations = const [
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ];
    } else if (game.portraitOnly) {
      orientations = const [DeviceOrientation.portraitUp];
    } else {
      orientations = const [
        DeviceOrientation.portraitUp,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ];
    }
    SystemChrome.setPreferredOrientations(orientations);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    WakelockPlus.enable();
  }

  void _restoreSystemUi() {
    if (_systemUiRestored) return;
    _systemUiRestored = true;
    WakelockPlus.disable();
    SystemChrome.setPreferredOrientations(const [DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  WebViewController _createController() {
    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (progress) {
            if (mounted) setState(() => _progress = progress);
          },
          onPageStarted: (_) {
            if (mounted) setState(() => _loading = true);
          },
          onPageFinished: (_) {
            if (mounted) {
              setState(() {
                _loading = false;
                _progress = 100;
              });
            }
          },
          onWebResourceError: (error) {
            if (!(error.isForMainFrame ?? true) || !mounted) return;
            setState(() {
              _loading = false;
              _error = ref.read(isOnlineProvider)
                  ? 'This game could not be loaded right now. Please try again.'
                  : 'You are offline. Connect to the internet to play.';
            });
          },
          onNavigationRequest: _handleNavigation,
        ),
      );

    final platform = controller.platform;
    if (platform is AndroidWebViewController) {
      platform.setMediaPlaybackRequiresUserGesture(false);
    }
    return controller;
  }

  /// Keeps web navigation inside the game. Store links and other app
  /// schemes opened by a game are handed to the system.
  Future<NavigationDecision> _handleNavigation(NavigationRequest request) async {
    final uri = Uri.tryParse(request.url);
    if (uri == null) return NavigationDecision.prevent;
    if (_inWebViewSchemes.contains(uri.scheme)) {
      return NavigationDecision.navigate;
    }
    await launchUrl(uri, mode: LaunchMode.externalApplication)
        .catchError((Object _) => false);
    return NavigationDecision.prevent;
  }

  Future<void> _load() async {
    if (!mounted) return;
    final rawUrl = widget.game.gameUrl;
    final uri = Uri.tryParse(rawUrl);

    if (uri == null || !uri.hasScheme) {
      setState(() {
        _loading = false;
        _error = 'This game link is not valid.';
      });
      return;
    }

    if (!ref.read(isOnlineProvider)) {
      setState(() {
        _loading = false;
        _error = 'You are offline. Connect to the internet to play.';
      });
      return;
    }

    assert(() {
      if (uri.toString() != rawUrl) {
        debugPrint('PlayHub: gameURL normalised by Uri.parse for ${widget.game.id}');
      }
      return true;
    }());

    setState(() {
      _error = null;
      _loading = true;
      _progress = 0;
    });

    try {
      await _controller.loadRequest(uri);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'This game could not be loaded right now. Please try again.';
      });
    }
  }

  Future<bool> _confirmExit() async {
    final leave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave game?'),
        content: const Text('Your progress in this game may not be saved.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep playing'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Leave'),
          ),
        ],
      ),
    );
    return leave ?? false;
  }

  void _exit() {
    unawaited(
      _controller.loadRequest(Uri.parse('about:blank')).catchError((_) {}),
    );
    _restoreSystemUi();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final insets = MediaQuery.paddingOf(context);
    const buttonSize = 44.0;

    final left = (insets.left + _closeOffset.dx)
        .clamp(0.0, size.width - buttonSize)
        .toDouble();
    final top = (insets.top + _closeOffset.dy)
        .clamp(0.0, size.height - buttonSize)
        .toDouble();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final leave = await _confirmExit();
        if (leave && mounted) _exit();
      },
      child: Theme(
        data: AppTheme.dark,
        child: Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            children: [
              Positioned.fill(child: WebViewWidget(controller: _controller)),
              Positioned.fill(
                child: IgnorePointer(
                  ignoring: !(_loading && _error == null),
                  child: AnimatedOpacity(
                    opacity: _loading && _error == null ? 1 : 0,
                    duration: const Duration(milliseconds: 350),
                    child: _LoadingOverlay(
                      game: widget.game,
                      progress: _progress,
                    ),
                  ),
                ),
              ),
              if (_error != null)
                Positioned.fill(
                  child: _ErrorOverlay(
                    message: _error!,
                    onRetry: _load,
                    onExit: _exit,
                  ),
                ),
              Positioned(
                left: left,
                top: top,
                child: GestureDetector(
                  onPanUpdate: (details) => setState(() {
                    final next = Offset(left, top) + details.delta;
                    _closeOffset =
                        Offset(next.dx - insets.left, next.dy - insets.top);
                  }),
                  child: _CloseButton(onTap: _exit, size: buttonSize),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CloseButton extends StatelessWidget {
  const _CloseButton({required this.onTap, required this.size});

  final VoidCallback onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Close game',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.black.withValues(alpha: 0.35),
            border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
          ),
          child: const Icon(Icons.close_rounded, color: Colors.white, size: 22),
        ),
      ),
    );
  }
}

class _LoadingOverlay extends StatelessWidget {
  const _LoadingOverlay({required this.game, required this.progress});

  final Game game;
  final int progress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fraction = (progress / 100).clamp(0.05, 1.0).toDouble();

    return GradientBackground(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 104,
                height: 104,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.violet.withValues(alpha: 0.45),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: GameImage(url: game.iconImage),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                game.title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleLarge?.copyWith(color: Colors.white),
              ),
              const SizedBox(height: 20),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: SizedBox(
                  width: 220,
                  height: 6,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: ColoredBox(
                          color: Colors.white.withValues(alpha: 0.12),
                        ),
                      ),
                      Positioned.fill(
                        child: AnimatedFractionallySizedBox(
                          duration: const Duration(milliseconds: 250),
                          alignment: Alignment.centerLeft,
                          widthFactor: fraction,
                          child: const DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: AppColors.primaryGradient,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Loading $progress%',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorOverlay extends StatelessWidget {
  const _ErrorOverlay({
    required this.message,
    required this.onRetry,
    required this.onExit,
  });

  final String message;
  final VoidCallback onRetry;
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GradientBackground(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.pink.withValues(alpha: 0.15),
                    border: Border.all(
                      color: AppColors.pink.withValues(alpha: 0.4),
                    ),
                  ),
                  child: const Icon(
                    Icons.wifi_off_rounded,
                    color: AppColors.pink,
                    size: 34,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 24),
                GradientButton(
                  label: 'Retry',
                  icon: Icons.refresh_rounded,
                  height: 50,
                  onPressed: onRetry,
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: onExit,
                  child: Text(
                    'Back to games',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.8)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
