import 'package:flutter/foundation.dart';

/// A gameplay clip reference from the catalog.
@immutable
class GameVideo {
  const GameVideo({
    required this.playgamaId,
    required this.externalUrl,
    required this.type,
  });

  factory GameVideo.fromJson(Map<String, dynamic> json) => GameVideo(
        playgamaId: _readString(json['playgama_id']),
        externalUrl: _readString(json['external_url']),
        type: _readString(json['type']).toLowerCase(),
      );

  final String playgamaId;
  final String externalUrl;
  final String type;

  bool get isGameplay => type == 'gameplay';
}

/// One playable HTML5 game.
///
/// [gameUrl] is stored exactly as it appears in the catalog. It carries the
/// partner `clid` used for revenue attribution, so it is never trimmed,
/// re-encoded or rebuilt anywhere in the app.
@immutable
class Game {
  const Game({
    required this.id,
    required this.slug,
    required this.title,
    required this.description,
    required this.howToPlay,
    required this.gameUrl,
    required this.genres,
    required this.tags,
    required this.images,
    required this.videos,
    required this.mobileReady,
    required this.horizontal,
    required this.vertical,
    required this.hasInGamePurchases,
    required this.supportedLanguages,
    required this.gender,
    required this.searchKey,
  });

  factory Game.fromJson(Map<String, dynamic> json) {
    final orientation = json['screenOrientation'];
    final hasOrientation = orientation is Map;
    final orientationStr = _readString(json['orientation']).toLowerCase();
    final title = _readString(json['title']).trim();
    final slug = _readString(json['slug']);
    final rawId = _readString(json['id']);
    final rawUrl = _readString(json['gameURL'] ?? json['gameUrl']);
    final rawVideos = json['videos'];

    final combinedGenres = [
      ..._readStringList(json['genres']),
      ..._readStringList(json['categories']),
    ];

    return Game(
      id: rawId.isNotEmpty ? rawId : slug,
      slug: slug,
      title: title,
      description: _readString(json['description']),
      howToPlay: _readString(json['howToPlayText']),
      gameUrl: rawUrl,
      genres: combinedGenres
          .map((g) => g.trim().toLowerCase())
          .where((g) => g.isNotEmpty)
          .toSet()
          .toList(growable: false),
      tags: _readStringList(json['tags']),
      images: _readStringList(json['images'])
          .where((u) => u.isNotEmpty)
          .toList(growable: false),
      videos: rawVideos is List
          ? rawVideos
              .whereType<Map<String, dynamic>>()
              .map(GameVideo.fromJson)
              .toList(growable: false)
          : const <GameVideo>[],
      mobileReady: _readStringList(json['mobileReady']),
      horizontal: hasOrientation
          ? _readBool(orientation['horizontal'], fallback: true)
          : (orientationStr == 'landscape' ||
              orientationStr == 'any' ||
              orientationStr.isEmpty),
      vertical: hasOrientation
          ? _readBool(orientation['vertical'], fallback: true)
          : (orientationStr == 'portrait' ||
              orientationStr == 'any' ||
              orientationStr.isEmpty),
      hasInGamePurchases:
          _readString(json['inGamePurchases']).toLowerCase() == 'yes',
      supportedLanguages: _readStringList(json['supportedLanguages']),
      gender: _readStringList(json['gender']),
      searchKey: title.toLowerCase(),
    );
  }

  final String id;
  final String slug;
  final String title;
  final String description;
  final String howToPlay;
  final String gameUrl;
  final List<String> genres;
  final List<String> tags;
  final List<String> images;
  final List<GameVideo> videos;
  final List<String> mobileReady;
  final bool horizontal;
  final bool vertical;
  final bool hasInGamePurchases;
  final List<String> supportedLanguages;
  final List<String> gender;

  /// Lower-cased title, precomputed for fast search.
  final String searchKey;

  String? get previewImage => images.isNotEmpty ? images.first : null;
  String? get iconImage => images.length > 1 ? images[1] : previewImage;
  String? get primaryGenre => genres.isNotEmpty ? genres.first : null;

  bool get isAndroidReady =>
      mobileReady.isEmpty ||
      mobileReady.any((m) => m.trim().toLowerCase() == 'for android');

  bool get landscapeOnly => horizontal && !vertical;
  bool get portraitOnly => vertical && !horizontal;

  Game copyWith({
    String? id,
    String? slug,
    String? title,
    String? description,
    String? howToPlay,
    String? gameUrl,
    List<String>? genres,
    List<String>? tags,
    List<String>? images,
    List<GameVideo>? videos,
    List<String>? mobileReady,
    bool? horizontal,
    bool? vertical,
    bool? hasInGamePurchases,
    List<String>? supportedLanguages,
    List<String>? gender,
    String? searchKey,
  }) {
    return Game(
      id: id ?? this.id,
      slug: slug ?? this.slug,
      title: title ?? this.title,
      description: description ?? this.description,
      howToPlay: howToPlay ?? this.howToPlay,
      gameUrl: gameUrl ?? this.gameUrl,
      genres: genres ?? this.genres,
      tags: tags ?? this.tags,
      images: images ?? this.images,
      videos: videos ?? this.videos,
      mobileReady: mobileReady ?? this.mobileReady,
      horizontal: horizontal ?? this.horizontal,
      vertical: vertical ?? this.vertical,
      hasInGamePurchases: hasInGamePurchases ?? this.hasInGamePurchases,
      supportedLanguages: supportedLanguages ?? this.supportedLanguages,
      gender: gender ?? this.gender,
      searchKey: searchKey ?? this.searchKey,
    );
  }

  @override
  bool operator ==(Object other) => other is Game && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

String _readString(Object? value) => value == null ? '' : value.toString();

List<String> _readStringList(Object? value) {
  if (value is List) {
    final list = <String>[];
    for (final e in value) {
      if (e is List) {
        list.addAll(_readStringList(e));
      } else if (e != null) {
        final str = e.toString().trim();
        if (str.isNotEmpty) list.add(str);
      }
    }
    return list;
  }
  if (value is String && value.trim().isNotEmpty) {
    return <String>[value.trim()];
  }
  return const <String>[];
}

bool _readBool(Object? value, {required bool fallback}) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) return value.toLowerCase() == 'true';
  return fallback;
}
