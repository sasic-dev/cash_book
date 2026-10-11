import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static TextTheme _applyFont(String fontFamily, TextTheme base) {
    try {
      switch (fontFamily.toLowerCase().trim()) {
        case 'inter':
          return GoogleFonts.interTextTheme(base);
        case 'roboto':
          return GoogleFonts.robotoTextTheme(base);
        case 'poppins':
          return GoogleFonts.poppinsTextTheme(base);
        case 'outfit':
          return GoogleFonts.outfitTextTheme(base);
        case 'lato':
          return GoogleFonts.latoTextTheme(base);
        case 'jetbrains mono':
          return GoogleFonts.jetBrainsMonoTextTheme(base);
        case 'merriweather':
          return GoogleFonts.merriweatherTextTheme(base);
        case 'system':
        default:
          return base;
      }
    } catch (_) {
      return base;
    }
  }

  static ThemeData buildLightTheme({
    Color primaryColor = const Color(0xFF1E40AF),
    String fontFamily = 'Inter',
  }) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: Brightness.light,
      surface: const Color(0xFFF8FAFC),
    );

    final rawTheme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: const Color(0xFFF8FAFC),
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 1,
        scrolledUnderElevation: 3,
        shadowColor: Color(0x1A0F172A),
        backgroundColor: Color(0xFFF8FAFC),
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color(0xFF0F172A),
        ),
        iconTheme: IconThemeData(color: Color(0xFF334155)),
      ),
      cardTheme: const CardThemeData(
        elevation: 2,
        shadowColor: Color(0x140F172A),
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
          side: BorderSide(color: Color(0xFFE2E8F0)),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        elevation: 4,
        shadowColor: const Color(0x1E0F172A),
        indicatorShape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
        ),
        indicatorColor: const Color(0xFFE2E8F0),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: primaryColor,
            );
          }
          return const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Color(0xFF64748B),
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: primaryColor, size: 24);
          }
          return const IconThemeData(color: Color(0xFF64748B), size: 24);
        }),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: Color(0xFFCBD5E1)),
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: Color(0xFFCBD5E1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: primaryColor, width: 1.5),
        ),
        errorBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: Colors.red, width: 1.5),
        ),
      ),
      dialogTheme: const DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
        ),
        backgroundColor: Colors.white,
        elevation: 8,
        shadowColor: Color(0x33000000),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          elevation: 2,
          shadowColor: const Color(0x26000000),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.zero,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        elevation: 4,
        highlightElevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
        ),
      ),
      chipTheme: const ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
        ),
        elevation: 1,
        pressElevation: 2,
        shadowColor: Color(0x140F172A),
      ),
    );

    return rawTheme.copyWith(
      textTheme: _applyFont(fontFamily, rawTheme.textTheme),
    );
  }

  static ThemeData buildDarkTheme({
    Color primaryColor = const Color(0xFF1E40AF),
    String fontFamily = 'Inter',
  }) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: Brightness.dark,
      surface: const Color(0xFF0F172A),
    );

    final rawTheme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: const Color(0xFF090D16),
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 1,
        scrolledUnderElevation: 3,
        shadowColor: Color(0x33000000),
        backgroundColor: Color(0xFF0F172A),
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color(0xFFF8FAFC),
        ),
        iconTheme: IconThemeData(color: Color(0xFFCBD5E1)),
      ),
      cardTheme: const CardThemeData(
        elevation: 3,
        shadowColor: Color(0x40000000),
        color: Color(0xFF1E293B),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
          side: BorderSide(color: Color(0xFF334155)),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 4,
        shadowColor: const Color(0x33000000),
        indicatorShape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
        ),
        indicatorColor: const Color(0xFF334155),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: colorScheme.primary,
            );
          }
          return const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Color(0xFF94A3B8),
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: colorScheme.primary, size: 24);
          }
          return const IconThemeData(color: Color(0xFF94A3B8), size: 24);
        }),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF1E293B),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: Color(0xFF475569)),
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: Color(0xFF475569)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
        ),
        errorBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: Colors.redAccent, width: 1.5),
        ),
      ),
      dialogTheme: const DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
        ),
        backgroundColor: Color(0xFF1E293B),
        elevation: 8,
        shadowColor: Color(0x66000000),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          elevation: 2,
          shadowColor: const Color(0x40000000),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.zero,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        elevation: 4,
        highlightElevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
        ),
      ),
      chipTheme: const ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
        ),
        elevation: 1,
        pressElevation: 2,
        shadowColor: Color(0x40000000),
      ),
    );

    return rawTheme.copyWith(
      textTheme: _applyFont(fontFamily, rawTheme.textTheme),
    );
  }
}
