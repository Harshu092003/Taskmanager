import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Color palette — deep navy + amber accent
  static const Color background = Color(0xFF0F1117);
  static const Color surface = Color(0xFF1A1D27);
  static const Color surfaceVariant = Color(0xFF252836);
  static const Color border = Color(0xFF2E3144);
  static const Color accent = Color(0xFFF5A623);
  static const Color accentLight = Color(0xFFFFD07F);
  static const Color textPrimary = Color(0xFFF0F0F5);
  static const Color textSecondary = Color(0xFF8B8FA8);
  static const Color textMuted = Color(0xFF4A4E63);

  static const Color statusTodo = Color(0xFF5B8DEF);
  static const Color statusInProgress = Color(0xFFF5A623);
  static const Color statusDone = Color(0xFF3ECF8E);
  static const Color blockedColor = Color(0xFF6B3E3E);

  static const Color danger = Color(0xFFEF4444);

  static ThemeData get dark {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.dark(
        primary: accent,
        secondary: accentLight,
        surface: surface,
        error: danger,
      ),
      textTheme: GoogleFonts.plusJakartaSansTextTheme(
        ThemeData.dark().textTheme,
      ).apply(bodyColor: textPrimary, displayColor: textPrimary),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: textPrimary,
          letterSpacing: -0.3,
        ),
        iconTheme: const IconThemeData(color: textPrimary),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceVariant,
        hintStyle: GoogleFonts.plusJakartaSans(color: textMuted, fontSize: 14),
        labelStyle: GoogleFonts.plusJakartaSans(
          color: textSecondary,
          fontSize: 13,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: accent, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: Colors.black,
          minimumSize: const Size.fromHeight(50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: border),
        ),
        margin: const EdgeInsets.only(bottom: 10),
      ),
      dividerTheme: const DividerThemeData(color: border, thickness: 1),
      useMaterial3: true,
    );
  }
}

Color statusColor(String status) {
  switch (status) {
    case 'In Progress':
      return AppTheme.statusInProgress;
    case 'Done':
      return AppTheme.statusDone;
    default:
      return AppTheme.statusTodo;
  }
}

IconData statusIcon(String status) {
  switch (status) {
    case 'In Progress':
      return Icons.autorenew_rounded;
    case 'Done':
      return Icons.check_circle_rounded;
    default:
      return Icons.radio_button_unchecked_rounded;
  }
}
