import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:playhub/data/catalog_parser.dart';

Map<String, dynamic> _game(
  Object id,
  String title,
  String url,
  List<String> mobileReady, {
  List<String> genres = const ['puzzle'],
}) =>
    {
      'id': id,
      'slug': 'game-$id',
      'title': title,
      'description': '<p>Fun &amp; games</p>',
      'howToPlayText': 'Tap to play',
      'gameURL': url,
      'genres': genres,
      'tags': ['casual'],
      'images': ['https://cdn.example.com/$id/big.jpg', 'https://cdn.example.com/$id/icon.jpg'],
      'videos': [
        {'playgama_id': 'v$id', 'external_url': '', 'type': 'gameplay'},
      ],
      'mobileReady': mobileReady,
      'screenOrientation': {'horizontal': true, 'vertical': false},
      'inGamePurchases': 'No',
    };

void main() {
  const partnerUrl =
      'https://playgama.com/export/game/abc?clid=p_7f3a9c&utm_source=partner';

  test('keeps only Android games and preserves gameURL byte for byte', () {
    final raw = jsonEncode({
      'segments': [
        {
          'hits': [
            _game(1, 'Block Puzzle', partnerUrl, ['For Android', 'For IOS']),
            _game(2, 'Desktop Only', 'https://example.com/g2', ['For Desktop']),
            _game(3, 'Merge Town', 'https://example.com/g3?clid=x', ['For Android'],
                genres: ['Merge', 'Puzzle']),
          ],
        },
      ],
    });

    final catalog = parseCatalog(raw);

    expect(catalog.games.map((g) => g.id), ['1', '3']);
    expect(catalog.games.first.gameUrl, partnerUrl);
    expect(catalog.games.first.landscapeOnly, isTrue);
    expect(catalog.genres.first.genre, 'puzzle');
    expect(catalog.genres.first.count, 2);
  });

  test('skips games without a launch URL and de-duplicates ids', () {
    final raw = jsonEncode({
      'segments': [
        {
          'hits': [
            _game(1, 'A', partnerUrl, ['For Android']),
            _game(1, 'A again', partnerUrl, ['For Android']),
            _game(2, 'No URL', '', ['For Android']),
          ],
        },
      ],
    });

    final catalog = parseCatalog(raw);
    expect(catalog.games.length, 1);
    expect(catalog.byId['1']?.title, 'A');
  });
}
