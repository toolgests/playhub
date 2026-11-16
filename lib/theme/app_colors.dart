import 'package:flutter/material.dart';

abstract final class AppColors {
  static const Color bgTop = Color(0xFF0F0B1F);
  static const Color bgBottom = Color(0xFF1A1240);
  static const Color surfaceDark = Color(0xFF1C1538);
  static const Color navDark = Color(0xFF1A1438);

  static const Color lightBgTop = Color(0xFFF7F5FF);
  static const Color lightBgBottom = Color(0xFFECE6FF);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color inkLight = Color(0xFF1B1530);

  static const Color violet = Color(0xFF7C4DFF);
  static const Color pink = Color(0xFFFF4D8D);
  static const Color cyan = Color(0xFF22D3EE);

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [violet, pink],
  );

  static const LinearGradient coolGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [violet, cyan],
  );

  static const LinearGradient backgroundDark = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [bgTop, bgBottom],
  );

  static const LinearGradient backgroundLight = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [lightBgTop, lightBgBottom],
  );

  static const LinearGradient imageScrim = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    stops: [0.45, 1.0],
    colors: [Color(0x000F0B1F), Color(0xD90F0B1F)],
  );
}
