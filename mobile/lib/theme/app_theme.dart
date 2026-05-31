import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color _black = Color(0xFF0D0D0D);
  static const Color _white = Color(0xFFFAFAFA);
  static const Color _gold = Color(0xFFC9A84C);
  static const Color _goldLight = Color(0xFFE5C76B);
  static const Color _surface = Color(0xFF1A1A1A);
  static const Color _surfaceVariant = Color(0xFF252525);
  static const Color _error = Color(0xFFCF6679);
  static const Color _success = Color(0xFF4CAF7D);
  static const Color _warning = Color(0xFFE5A84C);

  static ThemeData get dark {
    final montserrat = GoogleFonts.montserratTextTheme();
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      textTheme: montserrat.apply(
        bodyColor: _white,
        displayColor: _white,
      ),
      colorScheme: const ColorScheme.dark(
        primary: _gold,
        onPrimary: _black,
        secondary: _goldLight,
        onSecondary: _black,
        surface: _surface,
        onSurface: _white,
        surfaceContainerHighest: _surfaceVariant,
        error: _error,
        onError: _white,
      ),
      scaffoldBackgroundColor: _black,
      appBarTheme: AppBarTheme(
        backgroundColor: _black,
        foregroundColor: _white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.montserrat(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: _white,
          letterSpacing: 0.5,
        ),
      ),
      cardTheme: CardThemeData(
        color: _surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFF2A2A2A)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _gold,
          foregroundColor: _black,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: GoogleFonts.montserrat(
            fontWeight: FontWeight.w600,
            fontSize: 15,
            letterSpacing: 0.5,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _gold,
          side: const BorderSide(color: _gold),
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: GoogleFonts.montserrat(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: _gold,
          textStyle: GoogleFonts.montserrat(
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _surfaceVariant,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF2A2A2A)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF2A2A2A)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _gold, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _error),
        ),
        labelStyle: const TextStyle(color: Color(0xFF888888)),
        hintStyle: const TextStyle(color: Color(0xFF555555)),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: _surface,
        selectedItemColor: _gold,
        unselectedItemColor: Color(0xFF555555),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFF2A2A2A),
        thickness: 1,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: _surfaceVariant,
        labelStyle: const TextStyle(color: _white, fontSize: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
    );
  }

  // Semantic colors
  static const Color success = _success;
  static const Color warning = _warning;
  static const Color gold = _gold;
  static const Color goldLight = _goldLight;
  static const Color surface = _surface;
  static const Color surfaceVariant = _surfaceVariant;
}

extension AppTextStyles on TextTheme {
  TextStyle get displayTitle => GoogleFonts.montserrat(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: const Color(0xFFFAFAFA),
        height: 1.2,
      );

  TextStyle get sectionTitle => GoogleFonts.montserrat(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: const Color(0xFFFAFAFA),
      );

  TextStyle get cardTitle => GoogleFonts.montserrat(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: const Color(0xFFFAFAFA),
      );

  TextStyle get bodyRegular => GoogleFonts.montserrat(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: const Color(0xFFCCCCCC),
      );

  TextStyle get caption => GoogleFonts.montserrat(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: const Color(0xFF888888),
      );
}
