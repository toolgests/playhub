import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

@immutable
class NetworkStatus {
  const NetworkStatus({required this.online, required this.wifi});

  factory NetworkStatus.fromResults(List<ConnectivityResult> results) {
    final online =
        results.isNotEmpty && results.any((r) => r != ConnectivityResult.none);
    final wifi = results.contains(ConnectivityResult.wifi) ||
        results.contains(ConnectivityResult.ethernet);
    return NetworkStatus(online: online, wifi: wifi);
  }

  final bool online;
  final bool wifi;

  @override
  bool operator ==(Object other) =>
      other is NetworkStatus && other.online == online && other.wifi == wifi;

  @override
  int get hashCode => Object.hash(online, wifi);
}

final networkStatusProvider = StreamProvider<NetworkStatus>((ref) async* {
  final connectivity = Connectivity();
  yield NetworkStatus.fromResults(await connectivity.checkConnectivity());
  yield* connectivity.onConnectivityChanged.map(NetworkStatus.fromResults);
});

/// Optimistic until the first connectivity result arrives.
final isOnlineProvider = Provider<bool>(
  (ref) => ref.watch(networkStatusProvider).asData?.value.online ?? true,
);
