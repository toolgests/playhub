import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_config.dart';
import '../data/catalog_repository.dart';
import '../models/catalog.dart';
import '../models/game.dart';

final catalogRepositoryProvider =
    Provider<CatalogRepository>((ref) => const CatalogRepository());

final catalogProvider = FutureProvider<Catalog>(
  (ref) => ref.watch(catalogRepositoryProvider).load(),
);

/// The loaded catalog, or an empty one while loading.
final catalogDataProvider = Provider<Catalog>(
  (ref) => ref.watch(catalogProvider).asData?.value ?? Catalog.empty,
);

@immutable
class HomeFilter {
  const HomeFilter({this.query = '', this.genre});

  final String query;
  final String? genre;

  bool get isDefault => query.trim().isEmpty && genre == null;

  @override
  bool operator ==(Object other) =>
      other is HomeFilter && other.query == query && other.genre == genre;

  @override
  int get hashCode => Object.hash(query, genre);
}

class HomeFilterNotifier extends Notifier<HomeFilter> {
  @override
  HomeFilter build() => const HomeFilter();

  void setQuery(String query) =>
      state = HomeFilter(query: query, genre: state.genre);

  void setGenre(String? genre) =>
      state = HomeFilter(query: state.query, genre: genre);

  void clear() => state = const HomeFilter();
}

final homeFilterProvider =
    NotifierProvider<HomeFilterNotifier, HomeFilter>(HomeFilterNotifier.new);

/// Games for the Home grid after search and genre filters.
final homeGamesProvider = Provider<List<Game>>((ref) {
  final games = ref.watch(catalogDataProvider).games;
  final filter = ref.watch(homeFilterProvider);
  if (filter.isDefault) return games;

  final query = filter.query.trim().toLowerCase();
  final genre = filter.genre;
  return games
      .where((g) =>
          (genre == null || g.genres.contains(genre)) &&
          (query.isEmpty || g.searchKey.contains(query)))
      .toList(growable: false);
});

final homeGenresProvider = Provider<List<GenreCount>>(
  (ref) => ref
      .watch(catalogDataProvider)
      .genres
      .take(AppConfig.homeGenreChips)
      .toList(growable: false),
);

/// Featured rail: games that have gameplay clips first, topped up with
/// the next games in catalog order.
final featuredGamesProvider = Provider<List<Game>>((ref) {
  final games = ref.watch(catalogDataProvider).games;
  const count = AppConfig.featuredCount;
  final picked = games.where((g) => g.videos.isNotEmpty).take(count).toList();
  if (picked.length < count) {
    final ids = picked.map((g) => g.id).toSet();
    picked.addAll(
      games.where((g) => !ids.contains(g.id)).take(count - picked.length),
    );
  }
  return List.unmodifiable(picked);
});

/// External games rail from live API (e.g., "PlayHub External Games").
final externalGamesProvider = Provider<ExternalGamesSection>(
  (ref) => ref.watch(catalogDataProvider).externalGames,
);

final gamesByGenreProvider =
    Provider.autoDispose.family<List<Game>, String>((ref, genre) {
  return ref
      .watch(catalogDataProvider)
      .games
      .where((g) => g.genres.contains(genre))
      .toList(growable: false);
});

final similarGamesProvider =
    Provider.autoDispose.family<List<Game>, Game>((ref, game) {
  final genre = game.primaryGenre;
  if (genre == null) return const <Game>[];
  return ref
      .watch(catalogDataProvider)
      .games
      .where((g) => g.id != game.id && g.genres.contains(genre))
      .take(AppConfig.similarGamesCount)
      .toList(growable: false);
});
