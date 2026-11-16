import 'dart:async';

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:video_player/video_player.dart';

/// Decides which on-screen cards may play a muted gameplay preview.
///
/// Every preview slot reports its visible fraction. Only the best
/// [maxControllers] slots above [visibilityThreshold] get a player, ranked
/// by priority and then by visibility. The total number of live
/// [VideoPlayerController]s, including ones still being released, never
/// exceeds [maxControllers]. Everything is released while the app is in the
/// background, while a game is running, or when settings or the network
/// disallow previews. Clips that fail or load too slowly are remembered so
/// their cards keep the static image.
class PreviewVideoManager extends ChangeNotifier {
  PreviewVideoManager({
    this.maxControllers = 2,
    this.visibilityThreshold = 0.6,
    this.initTimeout = const Duration(seconds: 8),
  }) {
    _lifecycle = AppLifecycleListener(
      onHide: _handleAppHidden,
      onShow: _handleAppShown,
    );
  }

  final int maxControllers;
  final double visibilityThreshold;
  final Duration initTimeout;

  late final AppLifecycleListener _lifecycle;

  final Map<String, _SlotReport> _reports = <String, _SlotReport>{};
  final Map<String, _ActivePreview> _active = <String, _ActivePreview>{};
  final Set<String> _failedUrls = <String>{};

  int _draining = 0;
  int _suspendCount = 0;
  bool _autoplay = true;
  bool _wifiOnly = false;
  bool _online = true;
  bool _onWifi = false;
  bool _appVisible = true;
  bool _disposed = false;
  Timer? _rebalanceTimer;

  bool get _enabled =>
      _autoplay &&
      _online &&
      _appVisible &&
      _suspendCount == 0 &&
      (!_wifiOnly || _onWifi);

  /// The ready, playing controller for [slotKey], if it won a slot.
  VideoPlayerController? controllerFor(String slotKey) {
    final preview = _active[slotKey];
    return preview != null && preview.ready && !preview.released
        ? preview.controller
        : null;
  }

  void report(
    String slotKey,
    String? url,
    double visibleFraction, {
    int priority = 0,
  }) {
    if (_disposed) return;
    if (url != null && visibleFraction > 0 && !_failedUrls.contains(url)) {
      _reports[slotKey] = _SlotReport(url, visibleFraction, priority);
    } else if (_reports.remove(slotKey) == null &&
        !_active.containsKey(slotKey)) {
      return;
    }
    _scheduleRebalance();
  }

  void unregister(String slotKey) {
    if (_disposed) return;
    _reports.remove(slotKey);
    if (_active.containsKey(slotKey)) _scheduleRebalance();
  }

  void updatePolicy({required bool autoplay, required bool wifiOnly}) {
    _autoplay = autoplay;
    _wifiOnly = wifiOnly;
    _rebalanceNow();
  }

  void updateNetwork({required bool online, required bool wifi}) {
    _online = online;
    _onWifi = wifi;
    _rebalanceNow();
  }

  /// Stops all previews, for example while a game is running.
  void suspend() {
    _suspendCount++;
    _rebalanceNow();
  }

  void resume() {
    if (_suspendCount > 0) _suspendCount--;
    _scheduleRebalance();
  }

  void _handleAppHidden() {
    _appVisible = false;
    _rebalanceNow();
  }

  void _handleAppShown() {
    _appVisible = true;
    _scheduleRebalance();
  }

  void _scheduleRebalance() {
    if (_disposed) return;
    _rebalanceTimer?.cancel();
    _rebalanceTimer = Timer(const Duration(milliseconds: 300), _rebalance);
  }

  void _rebalanceNow() {
    _rebalanceTimer?.cancel();
    _rebalance();
  }

  void _rebalance() {
    if (_disposed) return;

    final winners = <String>{};
    if (_enabled) {
      final candidates = _reports.entries
          .where((e) =>
              e.value.fraction >= visibilityThreshold &&
              !_failedUrls.contains(e.value.url))
          .toList()
        ..sort((a, b) {
          final byPriority = b.value.priority.compareTo(a.value.priority);
          return byPriority != 0
              ? byPriority
              : b.value.fraction.compareTo(a.value.fraction);
        });
      winners.addAll(candidates.take(maxControllers).map((e) => e.key));
    }

    var changed = false;
    for (final key in _active.keys.toList()) {
      final preview = _active[key]!;
      final keep = winners.contains(key) && _reports[key]?.url == preview.url;
      if (!keep) {
        _active.remove(key);
        _release(preview);
        changed = true;
      }
    }

    for (final key in winners) {
      if (_active.containsKey(key)) continue;
      if (_active.length + _draining >= maxControllers) break;
      unawaited(_start(key, _reports[key]!.url));
    }

    if (changed) notifyListeners();
  }

  Future<void> _start(String key, String url) async {
    final controller = VideoPlayerController.networkUrl(
      Uri.parse(url),
      videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
    );
    final preview = _ActivePreview(url, controller);
    _active[key] = preview;

    try {
      await controller.initialize().timeout(initTimeout);
      if (preview.released) return;
      await controller.setVolume(0);
      await controller.setLooping(true);
      if (preview.released) return;
      await controller.play();
      await _firstFrame(controller);
      if (preview.released || _disposed) return;
      preview.ready = true;
      notifyListeners();
    } catch (_) {
      _failedUrls.add(url);
      if (identical(_active[key], preview)) _active.remove(key);
      _release(preview);
      if (!_disposed) {
        notifyListeners();
        _scheduleRebalance();
      }
    }
  }

  /// Waits briefly until playback has produced a frame, so the cross-fade
  /// never reveals a black texture.
  Future<void> _firstFrame(VideoPlayerController controller) async {
    if (controller.value.position > Duration.zero) return;
    final completer = Completer<void>();
    void listener() {
      if (controller.value.position > Duration.zero && !completer.isCompleted) {
        completer.complete();
      }
    }

    controller.addListener(listener);
    try {
      await completer.future.timeout(
        const Duration(seconds: 3),
        onTimeout: () {},
      );
    } finally {
      controller.removeListener(listener);
    }
  }

  void _release(_ActivePreview preview) {
    if (preview.released) return;
    preview.released = true;
    _draining++;
    unawaited(_disposeController(preview));
  }

  Future<void> _disposeController(_ActivePreview preview) async {
    try {
      if (preview.controller.value.isInitialized) {
        await preview.controller.pause();
      }
    } catch (_) {}

    // Let the card rebuild without the VideoPlayer before the native player
    // goes away. In the background no frames run, so dispose right away.
    if (_appVisible && !_disposed) {
      await SchedulerBinding.instance.endOfFrame.timeout(
        const Duration(milliseconds: 500),
        onTimeout: () {},
      );
    }

    try {
      await preview.controller.dispose();
    } catch (_) {}

    _draining--;
    if (!_disposed) _scheduleRebalance();
  }

  @override
  void dispose() {
    _disposed = true;
    _rebalanceTimer?.cancel();
    _lifecycle.dispose();
    for (final preview in _active.values) {
      preview.released = true;
      unawaited(preview.controller.dispose());
    }
    _active.clear();
    _reports.clear();
    super.dispose();
  }
}

class _SlotReport {
  const _SlotReport(this.url, this.fraction, this.priority);

  final String url;
  final double fraction;
  final int priority;
}

class _ActivePreview {
  _ActivePreview(this.url, this.controller);

  final String url;
  final VideoPlayerController controller;
  bool ready = false;
  bool released = false;
}
