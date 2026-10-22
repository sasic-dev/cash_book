import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/app_constants.dart';

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
    Color primaryColor = const Color(AppConstants.defaultPrimaryColorValue),
    String fontFamily = AppConstants.defaultFontFamily,
  }) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: Brightness.light,
      surface: AppConstants.lightScaffoldBg,
    );

    final rawTheme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppConstants.lightScaffoldBg,
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 1,
        scrolledUnderElevation: 3,
        shadowColor: AppConstants.lightShadow,
        backgroundColor: AppConstants.lightScaffoldBg,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppConstants.lightTextPrimary,
        ),
        iconTheme: IconThemeData(color: Color(0xFF334155)),
      ),
      cardTheme: const CardThemeData(
        elevation: 2,
        shadowColor: AppConstants.lightCardShadow,
        color: AppConstants.lightCardBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
          side: BorderSide(color: AppConstants.lightBorder),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppConstants.lightCardBg,
        elevation: 4,
        shadowColor: const Color(0x1E0F172A),
        indicatorShape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
        ),
        indicatorColor: AppConstants.lightBorder,
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
            color: AppConstants.lightTextSecondary,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: primaryColor, size: 24);
          }
          return const IconThemeData(color: AppConstants.lightTextSecondary, size: 24);
        }),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppConstants.lightScaffoldBg,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: AppConstants.lightInputBorder),
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: AppConstants.lightInputBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: primaryColor, width: 1.5),
        ),
        errorBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: AppConstants.expenseRed, width: 1.5),
        ),
      ),
      dialogTheme: const DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
        ),
        backgroundColor: AppConstants.lightCardBg,
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
    Color primaryColor = const Color(AppConstants.defaultPrimaryColorValue),
    String fontFamily = AppConstants.defaultFontFamily,
  }) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: Brightness.dark,
      surface: AppConstants.darkSurface,
    );

    final rawTheme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppConstants.darkScaffoldBg,
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 1,
        scrolledUnderElevation: 3,
        shadowColor: AppConstants.darkShadow,
        backgroundColor: AppConstants.darkSurface,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppConstants.darkTextPrimary,
        ),
        iconTheme: IconThemeData(color: AppConstants.lightInputBorder),
      ),
      cardTheme: const CardThemeData(
        elevation: 3,
        shadowColor: AppConstants.darkCardShadow,
        color: AppConstants.darkCardBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
          side: BorderSide(color: AppConstants.darkBorder),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppConstants.darkSurface,
        elevation: 4,
        shadowColor: AppConstants.darkShadow,
        indicatorShape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
        ),
        indicatorColor: AppConstants.darkBorder,
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
            color: AppConstants.darkTextSecondary,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: colorScheme.primary, size: 24);
          }
          return const IconThemeData(color: AppConstants.darkTextSecondary, size: 24);
        }),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppConstants.darkCardBg,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: AppConstants.darkInputBorder),
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: AppConstants.darkInputBorder),
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
        backgroundColor: AppConstants.darkCardBg,
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
