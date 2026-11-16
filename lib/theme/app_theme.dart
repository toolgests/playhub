import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

abstract final class AppTheme {
  static final ThemeData dark = _build(Brightness.dark);
  static final ThemeData light = _build(Brightness.light);

  /// Light status bar icons, for dark backgrounds.
  static const SystemUiOverlayStyle overlayOnDark = SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.light,
  );

  /// Dark status bar icons, for light backgrounds.
  static const SystemUiOverlayStyle overlayOnLight = SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.dark,
  );

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final onSurface = isDark ? Colors.white : AppColors.inkLight;

    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.violet,
      brightness: brightness,
    ).copyWith(
      primary: AppColors.violet,
      onPrimary: Colors.white,
      secondary: AppColors.pink,
      onSecondary: Colors.white,
      tertiary: AppColors.cyan,
      surface: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      onSurface: onSurface,
    );

    final rajdhaniFamily = GoogleFonts.poppins().fontFamily;

    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      fontFamily: rajdhaniFamily,
    );

    final text = GoogleFonts.poppinsTextTheme(base.textTheme).apply(
      bodyColor: onSurface,
      displayColor: onSurface,
    );

    return base.copyWith(
      scaffoldBackgroundColor: isDark ? AppColors.bgTop : AppColors.lightBgTop,
      textTheme: text.copyWith(
        displayLarge: GoogleFonts.orbitron(
          textStyle: text.displayLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        displayMedium: GoogleFonts.orbitron(
          textStyle: text.displayMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        headlineLarge: GoogleFonts.orbitron(
          textStyle: text.headlineLarge?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
        ),
        headlineMedium: GoogleFonts.orbitron(
          textStyle: text.headlineMedium?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: 1.1,
          ),
        ),
        headlineSmall: GoogleFonts.orbitron(
          textStyle: text.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
        ),
        titleLarge: text.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          fontSize: 20,
          letterSpacing: 0.5,
        ),
        titleMedium: text.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
          fontSize: 17,
          letterSpacing: 0.4,
        ),
        titleSmall: text.titleSmall?.copyWith(
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
        bodyLarge: text.bodyLarge?.copyWith(
          fontWeight: FontWeight.w500,
          fontSize: 16,
        ),
        bodyMedium: text.bodyMedium?.copyWith(
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
        labelLarge: text.labelLarge?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: onSurface,
        centerTitle: false,
        titleTextStyle: GoogleFonts.orbitron(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.0,
          color: onSurface,
        ),
        systemOverlayStyle: isDark ? overlayOnDark : overlayOnLight,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark ? const Color(0xFF2A2052) : AppColors.inkLight,
        contentTextStyle: GoogleFonts.rajdhani(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected) ? Colors.white : null,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected) ? AppColors.violet : null,
        ),
        trackOutlineColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected) ? Colors.transparent : null,
        ),
      ),
      progressIndicatorTheme:
          const ProgressIndicatorThemeData(color: AppColors.pink),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: AppColors.pink,
        selectionHandleColor: AppColors.pink,
      ),
      splashColor: AppColors.violet.withValues(alpha: 0.12),
      highlightColor: Colors.transparent,
      dividerColor: onSurface.withValues(alpha: 0.08),
    );
  }
}
