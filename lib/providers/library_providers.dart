import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_config.dart';
import '../models/game.dart';
import 'catalog_providers.dart';
import 'core_providers.dart';

/// Favorite game ids, newest first.
class FavoritesNotifier extends Notifier<List<String>> {
  static const _key = 'favorites_v1';

  @override
  List<String> build() => List.unmodifiable(
        ref.watch(sharedPrefsProvider).getStringList(_key) ?? const <String>[],
      );

  /// Returns true when the game is a favorite after the call.
  bool toggle(String id) {
    final next = [...state];
    final added = !next.remove(id);
    if (added) next.insert(0, id);
    _commit(next);
    return added;
  }

  void _commit(List<String> next) {
    state = List.unmodifiable(next);
    ref.read(sharedPrefsProvider).setStringList(_key, next);
  }
}

final favoritesProvider =
    NotifierProvider<FavoritesNotifier, List<String>>(FavoritesNotifier.new);

final favoriteGamesProvider = Provider<List<Game>>(
  (ref) => ref.watch(catalogDataProvider).resolve(ref.watch(favoritesProvider)),
);

/// Recently played game ids, most recent first.
class RecentlyPlayedNotifier extends Notifier<List<String>> {
  static const _key = 'recently_played_v1';

  @override
  List<String> build() => List.unmodifiable(
        ref.watch(sharedPrefsProvider).getStringList(_key) ?? const <String>[],
      );

  void add(String id) {
    final next = [id, ...state.where((e) => e != id)];
    if (next.length > AppConfig.recentLimit) {
      next.removeRange(AppConfig.recentLimit, next.length);
    }
    _commit(next);
  }

  void clear() => _commit(const <String>[]);

  void _commit(List<String> next) {
    state = List.unmodifiable(next);
    ref.read(sharedPrefsProvider).setStringList(_key, next);
  }
}

final recentlyPlayedProvider =
    NotifierProvider<RecentlyPlayedNotifier, List<String>>(
  RecentlyPlayedNotifier.new,
);

final recentGamesProvider = Provider<List<Game>>(
  (ref) =>
      ref.watch(catalogDataProvider).resolve(ref.watch(recentlyPlayedProvider)),
);
