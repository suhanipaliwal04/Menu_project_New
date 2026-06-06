import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ── Color Palette (Nude / Classic Refined) ─────────────────────────────────
  static const Color background = Color(0xFFFDF5E6); // Light Beige (Linen)
  static const Color surface = Color(0xFFFFFFFF); 
  static const Color surfaceAlt = Color(0xFFF5E6D3); // Warm Sand / Soft Tan
  static const Color card = Colors.white;

  static const Color primary = Color(0xFFC19A6B); // Camel
  static const Color primaryGlow = Color(0x1AC19A6B);
  static const Color secondary = Color(0xFF7B3F00); // Light Brown
  static const Color accent = Color(0xFFAF6F09); // Caramel Brown
  
  static const Color textPrimary = Color(0xFF3E2723); // Extremely Deep Brown (Near Black)
  static const Color textSecondary = Color(0xFF8D6E63); // Soft Brown
  static const Color textMuted = Color(0xFFBCAAA4); // Muted Tan

  static const Color divider = Color(0xFFEFEBE9);
  static const Color success = Color(0xFF4E6E4D); // Muted forest green
  static const Color warning = Color(0xFFD4AC0D);
  static const Color error = Color(0xFF922B21);

  static const Color vegGreen = Color(0xFF4E6E4D);
  static const Color nonVegRed = Color(0xFF922B21);

  // ── Gradients ─────────────────────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFFD35400), Color(0xFFE67E22)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient headerGradient = LinearGradient(
    colors: [Color(0xFFFBF9F6), Color(0xFFF3F0EC)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // ── Theme ─────────────────────────────────────────────────────────────────
  static ThemeData get lightTheme {
    final base = ThemeData.light();
    return base.copyWith(
      scaffoldBackgroundColor: Colors.transparent,
      colorScheme: const ColorScheme.light(
        primary: primary,
        secondary: secondary,
        surface: surface,
        error: error,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textPrimary,
      ),
      textTheme: GoogleFonts.outfitTextTheme(base.textTheme).apply(
        bodyColor: textPrimary,
        displayColor: textPrimary,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.outfit(
          color: textPrimary,
          fontSize: 22,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
        ),
        iconTheme: const IconThemeData(color: textPrimary),
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
        ),
      ),
      cardTheme: CardThemeData(
        color: card,
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.05),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: divider, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceAlt,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primary, width: 1.0),
        ),
        hintStyle: GoogleFonts.outfit(color: textMuted, fontSize: 15),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: Colors.white,
        selectedColor: primaryGlow,
        labelStyle: GoogleFonts.outfit(color: textSecondary, fontSize: 13),
        secondaryLabelStyle: GoogleFonts.outfit(color: primary, fontSize: 13),
        side: const BorderSide(color: divider),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: primary,
        unselectedItemColor: textSecondary,
        selectedLabelStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
        unselectedLabelStyle: TextStyle(fontSize: 12),
        elevation: 10,
        type: BottomNavigationBarType.fixed,
      ),
      dividerTheme: const DividerThemeData(color: divider, thickness: 1),
    );
  }

  // Legacy alias for compatibility during transition
  static ThemeData get darkTheme => lightTheme;

  static Color healthColor(int? score) {
    if (score == null) return textMuted;
    if (score >= 7) return const Color(0xFF2D5A27);
    if (score >= 4) return const Color(0xFFD4AC0D);
    return const Color(0xFF922B21);
  }

  static Color healthLabelColor(String? label) {
    if (label == null || label.isEmpty) return textMuted;
    final l = label.toLowerCase();
    if (l.contains('healthy') || l.contains('high') || l.contains('good')) return const Color(0xFF2D5A27);
    if (l.contains('moderate') || l.contains('medium')) return const Color(0xFFD4AC0D);
    return const Color(0xFF922B21);
  }
}
