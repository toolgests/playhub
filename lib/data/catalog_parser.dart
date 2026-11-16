import 'dart:convert';

import '../models/catalog.dart';
import '../models/game.dart';

/// Parses the raw catalog JSON. Top-level so it can run inside `compute`.
///
/// Accepts `{ "segments": [ { "hits": [...] } ] }` and, as a fallback,
/// a bare list of games. Keeps only games that are Android-ready and have a
/// launch URL, and de-duplicates by id while preserving catalog order.
Catalog parseCatalog(String raw) {
  final decoded = jsonDecode(raw);
  final hits = <Map<String, dynamic>>[];
  ExternalGamesSection externalGamesSection = const ExternalGamesSection();

  if (decoded is Map<String, dynamic>) {
    // 1. Playgama segments format (from assets/games.json)
    final segments = decoded['segments'];
    if (segments is List) {
      for (final segment in segments) {
        if (segment is! Map<String, dynamic>) continue;
        final segmentHits = segment['hits'];
        if (segmentHits is List) {
          hits.addAll(segmentHits.whereType<Map<String, dynamic>>());
        }
      }
    }

    // 2. Live API format ({"count": 2518, "games": [...]})
    final gamesList = decoded['games'];
    if (gamesList is List) {
      hits.addAll(gamesList.whereType<Map<String, dynamic>>());
    }

    // 3. External games format ({"heading": "PlayHub External Games", "isExternalGames": true, "games": [...]})
    final extGames = decoded['externalGames'];
    if (extGames is Map) {
      final extMap = extGames is Map<String, dynamic>
          ? extGames
          : Map<String, dynamic>.from(extGames);
      final heading =
          (extMap['heading'] ?? 'PlayHub External Games').toString();
      final isExternal = extMap['isExternalGames'] == true ||
          extMap['isExternalGames']?.toString().toLowerCase() == 'true';
      final extList = extMap['games'];
      final extGamesList = <Game>[];
      if (extList is List) {
        for (final item in extList) {
          if (item is Map) {
            final gameMap = item is Map<String, dynamic>
                ? item
                : Map<String, dynamic>.from(item);
            final g = Game.fromJson(gameMap);
            if (g.id.isNotEmpty && g.title.isNotEmpty && g.gameUrl.isNotEmpty) {
              extGamesList.add(g);
            }
          }
        }
      }
      externalGamesSection = ExternalGamesSection(
        heading: heading,
        isExternalGames: isExternal,
        games: List.unmodifiable(extGamesList),
      );
    }
  } else if (decoded is List) {
    hits.addAll(decoded.whereType<Map<String, dynamic>>());
  }

  final games = <Game>[];
  final byId = <String, Game>{};
  final genreCounts = <String, int>{};

  for (final json in hits) {
    final game = Game.fromJson(json);
    if (game.id.isEmpty || game.title.isEmpty || game.gameUrl.isEmpty) continue;
    if (!game.isAndroidReady) continue;
    if (byId.containsKey(game.id)) continue;

    games.add(game);
    byId[game.id] = game;
    for (final genre in game.genres.toSet()) {
      genreCounts[genre] = (genreCounts[genre] ?? 0) + 1;
    }
  }

  // Enrich any external games that might lack thumbnails if catalog has them,
  // while strictly keeping only the external games in externalGamesSection.
  if (externalGamesSection.games.isNotEmpty) {
    final enriched = externalGamesSection.games.map((ext) {
      if (ext.images.isEmpty && byId[ext.id] != null) {
        final match = byId[ext.id]!;
        if (match.images.isNotEmpty) {
          return ext.copyWith(images: match.images);
        }
      }
      return ext;
    }).toList(growable: false);

    externalGamesSection = ExternalGamesSection(
      heading: externalGamesSection.heading,
      isExternalGames: externalGamesSection.isExternalGames,
      games: List.unmodifiable(enriched),
    );
  }

  // Ensure external games are also registered in byId map for lookup/detail navigation
  for (final extGame in externalGamesSection.games) {
    byId.putIfAbsent(extGame.id, () => extGame);
  }

  final genres = genreCounts.entries
      .map((e) => GenreCount(e.key, e.value))
      .toList()
    ..sort((a, b) => b.count.compareTo(a.count));

  return Catalog(
    games: List.unmodifiable(games),
    byId: Map.unmodifiable(byId),
    genres: List.unmodifiable(genres),
    externalGames: externalGamesSection,
  );
}
