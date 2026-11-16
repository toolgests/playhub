import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// "match-3" becomes "Match 3", "io" becomes "IO".
String genreLabel(String genre) {
  return genre
      .split(RegExp(r'[-_\s]+'))
      .where((part) => part.isNotEmpty)
      .map((part) => part.length <= 2
          ? part.toUpperCase()
          : part[0].toUpperCase() + part.substring(1))
      .join(' ');
}

const Map<String, IconData> _genreIcons = {
  'puzzle': Icons.extension_rounded,
  'arcade': Icons.videogame_asset_rounded,
  'action': Icons.flash_on_rounded,
  'racing': Icons.sports_motorsports_rounded,
  'car': Icons.directions_car_rounded,
  'cozy': Icons.spa_rounded,
  'strategy': Icons.psychology_rounded,
  'brain': Icons.lightbulb_rounded,
  'logic': Icons.lightbulb_rounded,
  'sport': Icons.sports_soccer_rounded,
  'shoot': Icons.gps_fixed_rounded,
  'adventure': Icons.explore_rounded,
  'casual': Icons.sentiment_very_satisfied_rounded,
  'merge': Icons.merge_type_rounded,
  'match': Icons.grid_view_rounded,
  'card': Icons.style_rounded,
  'board': Icons.casino_rounded,
  'idle': Icons.hourglass_bottom_rounded,
  'clicker': Icons.touch_app_rounded,
  'simulat': Icons.tune_rounded,
  'educat': Icons.school_rounded,
  'quiz': Icons.quiz_rounded,
  'trivia': Icons.quiz_rounded,
  'word': Icons.text_fields_rounded,
  'music': Icons.music_note_rounded,
  'rhythm': Icons.music_note_rounded,
  'multiplayer': Icons.groups_rounded,
  'horror': Icons.nightlight_round,
  'kids': Icons.child_care_rounded,
  'platform': Icons.stairs_rounded,
  'runner': Icons.directions_run_rounded,
  'run': Icons.directions_run_rounded,
  'fight': Icons.sports_mma_rounded,
  'tower': Icons.fort_rounded,
  'defense': Icons.shield_rounded,
  'rpg': Icons.auto_awesome_rounded,
  'dress': Icons.checkroom_rounded,
  'cooking': Icons.restaurant_rounded,
  'farm': Icons.agriculture_rounded,
  'bubble': Icons.bubble_chart_rounded,
  'hidden': Icons.search_rounded,
  'ball': Icons.sports_basketball_rounded,
  'io': Icons.public_rounded,
  'tycoon': Icons.trending_up_rounded,
  'relax': Icons.self_improvement_rounded,
};

IconData genreIcon(String genre) {
  final key = genre.toLowerCase();
  final exact = _genreIcons[key];
  if (exact != null) return exact;
  for (final entry in _genreIcons.entries) {
    if (entry.key.length > 2 && key.contains(entry.key)) return entry.value;
  }
  return Icons.sports_esports_rounded;
}

const List<LinearGradient> _tileGradients = [
  AppColors.primaryGradient,
  AppColors.coolGradient,
  LinearGradient(colors: [Color(0xFFFF4D8D), Color(0xFFFF8A4C)]),
  LinearGradient(colors: [Color(0xFF00C6A7), Color(0xFF22D3EE)]),
  LinearGradient(colors: [Color(0xFF5B5BF7), Color(0xFF22D3EE)]),
  LinearGradient(colors: [Color(0xFFF59E0B), Color(0xFFFF4D8D)]),
  LinearGradient(colors: [Color(0xFF10B981), Color(0xFF7C4DFF)]),
  LinearGradient(colors: [Color(0xFFFF4D8D), Color(0xFF7C4DFF)]),
];

LinearGradient genreGradient(int index) {
  final base = _tileGradients[index % _tileGradients.length];
  return LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: base.colors,
  );
}
