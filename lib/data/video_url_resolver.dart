import '../models/game.dart';

/// URL pattern for gameplay preview clips. `{id}` is replaced with
/// `videos[].playgama_id`.
const String kPreviewVideoUrlPattern =
    'https://static.playgama.com/p-video/{id}/orig_length_h640_6so.mp4';

const List<String> _playableExtensions = ['.mp4', '.webm'];

final Map<String, String?> _cache = <String, String?>{};

/// Returns a playable .mp4/.webm URL for [g], or null when there is none.
///
/// Order of preference: a direct media `external_url` on a gameplay clip,
/// then on any clip, then [kPreviewVideoUrlPattern] filled with the clip's
/// `playgama_id`. Null means the card shows its image only.
String? resolveVideoUrl(Game g) {
  if (g.videos.isEmpty) return null;
  return _cache.putIfAbsent(g.id, () => _resolve(g));
}

String? _resolve(Game g) {
  final ordered = <GameVideo>[
    ...g.videos.where((v) => v.isGameplay),
    ...g.videos.where((v) => !v.isGameplay),
  ];

  for (final video in ordered) {
    final direct = _directMediaUrl(video.externalUrl);
    if (direct != null) return direct;
  }

  if (kPreviewVideoUrlPattern.isEmpty) return null;

  for (final video in ordered) {
    if (video.playgamaId.isEmpty) continue;
    final url = kPreviewVideoUrlPattern.replaceAll(
      '{id}',
      Uri.encodeComponent(video.playgamaId),
    );
    if (Uri.tryParse(url)?.scheme == 'https') return url;
  }
  return null;
}

String? _directMediaUrl(String url) {
  if (url.isEmpty) return null;
  final uri = Uri.tryParse(url);
  if (uri == null || uri.scheme != 'https') return null;
  final path = uri.path.toLowerCase();
  return _playableExtensions.any(path.endsWith) ? url : null;
}
