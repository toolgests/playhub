import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../models/catalog.dart';
import 'catalog_parser.dart';

/// Loads the game catalog: prefers live API from [apiUrl],
/// and falls back smoothly to [assetPath] if offline or upon error.
class CatalogRepository {
  const CatalogRepository({
    this.assetPath = AppConfig.catalogAsset,
    this.apiUrl = AppConfig.liveGamesApiUrl,
  });

  final String assetPath;
  final String apiUrl;

  Future<Catalog> load() async {
    // 1. Try to fetch live catalog from the backend API
    debugPrint('🌐 [Catalog API] Fetching live games from: $apiUrl');
    try {
      final raw = await _fetchFromApi(apiUrl);
      if (raw != null && raw.isNotEmpty) {
        debugPrint(
          '🔄 [Catalog API] Parsing ${raw.length} bytes of live catalog JSON...',
        );
        final catalog = kIsWeb
            ? parseCatalog(raw)
            : await compute(parseCatalog, raw, debugLabel: 'parseLiveCatalog');
        if (catalog.games.isNotEmpty) {
          debugPrint(
            '✅ [Catalog API] SUCCESS! Parsed ${catalog.games.length} games, ${catalog.genres.length} categories, and external games (${catalog.externalGames.heading}: ${catalog.externalGames.games.length} games, isExternalGames=${catalog.externalGames.isExternalGames}) from API.',
          );
          return catalog;
        } else {
          debugPrint(
            '⚠️ [Catalog API] API returned empty games list. Falling back to asset.',
          );
        }
      }
    } catch (e, st) {
      debugPrint('❌ [Catalog API] Error fetching live catalog: $e\n$st');
    }

    // 2. Fallback to bundled assets/games.json
    debugPrint('📁 [Catalog API] Loading fallback from asset: $assetPath');
    final raw = await rootBundle.loadString(assetPath, cache: false);
    final catalog = kIsWeb
        ? parseCatalog(raw)
        : await compute(parseCatalog, raw, debugLabel: 'parseCatalog');
    debugPrint(
      '✅ [Catalog Asset] Loaded ${catalog.games.length} games from local assets.',
    );
    return catalog;
  }

  static Future<String?> _fetchFromApi(String url) async {
    try {
      final uri = Uri.parse(url);
      final headers = <String, String>{
        'Accept': 'application/json',
      };
      if (!kIsWeb) {
        headers['User-Agent'] =
            'Mozilla/5.0 (Linux; Android 14; PlayHub Mobile App) AppleWebKit/537.36';
      }

      final response = await http.get(
        uri,
        headers: headers,
      ).timeout(const Duration(seconds: 30));

      debugPrint(
        '📥 [Catalog API] HTTP Status: ${response.statusCode} ${response.reasonPhrase}',
      );

      if (response.statusCode == 200) {
        final raw = response.body;
        final preview = raw.substring(0, math.min(250, raw.length));
        debugPrint(
          '📄 [Catalog API] Response Size: ${(raw.length / 1024).toStringAsFixed(1)} KB',
        );
        debugPrint('📄 [Catalog API] Response Preview: $preview...');
        return raw;
      } else {
        debugPrint('❌ [Catalog API] Non-200 Response: ${response.body}');
      }
    } catch (e, st) {
      debugPrint('❌ [Catalog API] Network/HTTP Exception: $e\n$st');
    }
    return null;
  }
}
