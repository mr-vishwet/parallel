import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// PARALLEL theme — the V7 palette: warm paper, dark ink, cut-red accent.
///
/// PHASE 1 uses a single light theme (what the V7 screens were designed
/// in). The palette is kept in [ParallelPalette] as plain colour tokens so
/// phase 2 can add a dark variant by supplying a second palette to the
/// same [AppTheme] builder — no dual-theme system is built now.
class ParallelPalette {
  ParallelPalette._();

  // Warm paper backgrounds (V7 tokens BG0/BG1/BG2).
  static const Color paper = Color(0xFFF4F3F0);
  static const Color paper2 = Color(0xFFEDEBE7);
  static const Color paper3 = Color(0xFFE7E5E4);

  // Ink scale.
  static const Color ink = Color(0xFF1C1917);
  static const Color secondary = Color(0xFF57534E);
  static const Color muted = Color(0xFF78716C);

  // Accents.
  static const Color cutRed = Color(0xFFB03220);
  static const Color cutRedDeep = Color(0xFF8F2718);
  static const Color amberCta = Color(0xFFD97706);
  static const Color green = Color(0xFF34D399);
  static const Color amber = Color(0xFFFBBF24);
  static const Color cyan = Color(0xFF67E8F9);
  static const Color pink = Color(0xFFF472B6);
  static const Color blue = Color(0xFF60A5FA);
  static const Color violet = Color(0xFFA78BFA);

  // Surfaces.
  static const Color glass = Color(0xA6FFFFFF); // white 65%
  static const Color glassStrong = Color(0xD1FFFFFF); // white 82%
  static const Color card = Color(0xFFFFFFFF);
  static const Color hairline = Color(0x1A1C1917); // ink 10%
  static const Color danger = Color(0xFFB42318);
}

/// The app theme (single light theme in phase 1).
class AppTheme {
  AppTheme._();

  /// The V7 light theme. Space Grotesk for UI text, JetBrains Mono for
  /// hashes, ids and code-like labels.
  static ThemeData get light {
    const scheme = ColorScheme.light(
      primary: ParallelPalette.cutRed,
      onPrimary: Colors.white,
      secondary: ParallelPalette.amberCta,
      surface: ParallelPalette.card,
      onSurface: ParallelPalette.ink,
      error: ParallelPalette.danger,
    );
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: scheme,
      scaffoldBackgroundColor: ParallelPalette.paper,
    );
    final textTheme = GoogleFonts.spaceGroteskTextTheme(base.textTheme).copyWith(
      displaySmall: GoogleFonts.spaceGrotesk(
        fontSize: 32,
        fontWeight: FontWeight.w800,
        color: ParallelPalette.ink,
        height: 1.1,
      ),
      headlineSmall: GoogleFonts.spaceGrotesk(
        fontSize: 26,
        fontWeight: FontWeight.w700,
        color: ParallelPalette.ink,
        height: 1.15,
      ),
      titleLarge: GoogleFonts.spaceGrotesk(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: ParallelPalette.ink,
      ),
      titleMedium: GoogleFonts.spaceGrotesk(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: ParallelPalette.ink,
      ),
      bodyLarge: GoogleFonts.spaceGrotesk(
        fontSize: 16,
        color: ParallelPalette.ink,
      ),
      bodyMedium: GoogleFonts.spaceGrotesk(
        fontSize: 14,
        color: ParallelPalette.ink,
      ),
      bodySmall: GoogleFonts.spaceGrotesk(
        fontSize: 12,
        color: ParallelPalette.muted,
      ),
      labelLarge: GoogleFonts.spaceGrotesk(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
    );
    return base.copyWith(
      textTheme: textTheme,
      appBarTheme: const AppBarTheme(
        backgroundColor: ParallelPalette.paper,
        foregroundColor: ParallelPalette.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      cardTheme: CardThemeData(
        color: ParallelPalette.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: ParallelPalette.hairline),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: ParallelPalette.cutRed,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: ParallelPalette.ink,
          side: const BorderSide(color: ParallelPalette.hairline),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: ParallelPalette.glassStrong,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: ParallelPalette.hairline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: ParallelPalette.hairline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: ParallelPalette.cutRed,
            width: 1.5,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: ParallelPalette.paper,
        indicatorColor: ParallelPalette.cutRed.withValues(alpha: 0.12),
        labelTextStyle: WidgetStatePropertyAll(
          GoogleFonts.spaceGrotesk(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: ParallelPalette.hairline,
        thickness: 1,
        space: 1,
      ),
    );
  }

  /// Monospace style for hashes, snapshot ids and code-like labels.
  static TextStyle mono({
    double size = 13,
    FontWeight weight = FontWeight.w500,
    Color color = ParallelPalette.secondary,
  }) =>
      GoogleFonts.jetBrainsMono(
        fontSize: size,
        fontWeight: weight,
        color: color,
      );
}
