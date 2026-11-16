import 'package:flutter/foundation.dart';

import 'game.dart';

@immutable
class GenreCount {
  const GenreCount(this.genre, this.count);

  final String genre;
  final int count;
}

@immutable
class ExternalGamesSection {
  const ExternalGamesSection({
    this.heading = 'PlayHub External Games',
    this.isExternalGames = false,
    this.games = const <Game>[],
  });

  final String heading;
  final bool isExternalGames;
  final List<Game> games;

  bool get isVisible => isExternalGames && games.isNotEmpty;
}

/// The parsed, Android-filtered game catalog.
@immutable
class Catalog {
  const Catalog({
    required this.games,
    required this.byId,
    required this.genres,
    this.externalGames = const ExternalGamesSection(),
  });

  static const Catalog empty = Catalog(
    games: <Game>[],
    byId: <String, Game>{},
    genres: <GenreCount>[],
    externalGames: ExternalGamesSection(),
  );

  /// Games in catalog order.
  final List<Game> games;
  final Map<String, Game> byId;

  /// Genres sorted by how many games use them, most common first.
  final List<GenreCount> genres;

  /// External games rail from API (e.g., "PlayHub External Games").
  final ExternalGamesSection externalGames;

  bool get isEmpty => games.isEmpty;

  /// Maps stored ids back to games, skipping ids no longer in the catalog.
  List<Game> resolve(Iterable<String> ids) => [
        for (final id in ids)
          if (byId[id] case final Game game) game,
      ];
}
