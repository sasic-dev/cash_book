import 'package:flutter/material.dart';

/// Preset color options for app theming
class AppColorPreset {
  final String id;
  final String name;
  final Color primaryColor;
  final String description;

  const AppColorPreset({
    required this.id,
    required this.name,
    required this.primaryColor,
    required this.description,
  });
}

/// Preset currency definitions
class CurrencyOption {
  final String code;
  final String name;
  final String symbol;
  final bool defaultIndianGrouping;
  final int defaultDecimals;

  const CurrencyOption({
    required this.code,
    required this.name,
    required this.symbol,
    this.defaultIndianGrouping = false,
    this.defaultDecimals = 2,
  });
}

/// Preset date format definitions
class DateFormatPreset {
  final String pattern;
  final String label;

  const DateFormatPreset({
    required this.pattern,
    required this.label,
  });
}

class AppSettings {
  // Theme & Color
  final int primaryColorValue;
  final ThemeMode themeMode;

  // Typography
  final String fontFamily;
  final double fontScale; // 0.85 to 1.40

  // Currency
  final String currencyCode;
  final String currencySymbol;
  final bool symbolBeforeAmount;
  final int decimalDigits;
  final bool useIndianGrouping;

  // Date & Time
  final String dateFormatPattern;
  final bool is24HourTime;

  const AppSettings({
    this.primaryColorValue = 0xFF1E40AF, // Sapphire Indigo
    this.themeMode = ThemeMode.light,
    this.fontFamily = 'Inter',
    this.fontScale = 1.0,
    this.currencyCode = 'INR',
    this.currencySymbol = '₹',
    this.symbolBeforeAmount = true,
    this.decimalDigits = 2,
    this.useIndianGrouping = true,
    this.dateFormatPattern = 'dd MMM yyyy',
    this.is24HourTime = false,
  });

  Color get primaryColor => Color(primaryColorValue);

  // Available Color Presets
  static const List<AppColorPreset> colorPresets = [
    AppColorPreset(
      id: 'sapphire',
      name: 'Sapphire Indigo',
      primaryColor: Color(0xFF1E40AF),
      description: 'Modern corporate indigo blue',
    ),
    AppColorPreset(
      id: 'emerald',
      name: 'Emerald Green',
      primaryColor: Color(0xFF059669),
      description: 'Vibrant wealth & growth green',
    ),
    AppColorPreset(
      id: 'royal_violet',
      name: 'Royal Violet',
      primaryColor: Color(0xFF7C3AED),
      description: 'Fintech purple & royalty',
    ),
    AppColorPreset(
      id: 'crimson_rose',
      name: 'Crimson Rose',
      primaryColor: Color(0xFFE11D48),
      description: 'Bold expressive crimson rose',
    ),
    AppColorPreset(
      id: 'amber_sunset',
      name: 'Sunset Amber',
      primaryColor: Color(0xFFD97706),
      description: 'Warm gold & autumn amber',
    ),
    AppColorPreset(
      id: 'teal_ocean',
      name: 'Ocean Teal',
      primaryColor: Color(0xFF0D9488),
      description: 'Calm refreshing oceanic teal',
    ),
    AppColorPreset(
      id: 'slate_tech',
      name: 'Slate Tech',
      primaryColor: Color(0xFF334155),
      description: 'Minimal slate & obsidian',
    ),
    AppColorPreset(
      id: 'cyan_sky',
      name: 'Electric Cyan',
      primaryColor: Color(0xFF0284C7),
      description: 'Vivid futuristic sky cyan',
    ),
  ];

  // Available Font Presets
  static const List<String> fontPresets = [
    'System',
    'Inter',
    'Roboto',
    'Poppins',
    'Outfit',
    'Lato',
    'JetBrains Mono',
    'Merriweather',
  ];

  // Available Currencies
  static const List<CurrencyOption> presetCurrencies = [
    CurrencyOption(
      code: 'INR',
      name: 'Indian Rupee',
      symbol: '₹',
      defaultIndianGrouping: true,
      defaultDecimals: 2,
    ),
    CurrencyOption(
      code: 'USD',
      name: 'US Dollar',
      symbol: '\$',
      defaultIndianGrouping: false,
      defaultDecimals: 2,
    ),
    CurrencyOption(
      code: 'EUR',
      name: 'Euro',
      symbol: '€',
      defaultIndianGrouping: false,
      defaultDecimals: 2,
    ),
    CurrencyOption(
      code: 'GBP',
      name: 'British Pound',
      symbol: '£',
      defaultIndianGrouping: false,
      defaultDecimals: 2,
    ),
    CurrencyOption(
      code: 'JPY',
      name: 'Japanese Yen',
      symbol: '¥',
      defaultIndianGrouping: false,
      defaultDecimals: 0,
    ),
    CurrencyOption(
      code: 'AUD',
      name: 'Australian Dollar',
      symbol: 'A\$',
      defaultIndianGrouping: false,
      defaultDecimals: 2,
    ),
    CurrencyOption(
      code: 'CAD',
      name: 'Canadian Dollar',
      symbol: 'C\$',
      defaultIndianGrouping: false,
      defaultDecimals: 2,
    ),
    CurrencyOption(
      code: 'AED',
      name: 'UAE Dirham',
      symbol: 'AED',
      defaultIndianGrouping: false,
      defaultDecimals: 2,
    ),
    CurrencyOption(
      code: 'SGD',
      name: 'Singapore Dollar',
      symbol: 'S\$',
      defaultIndianGrouping: false,
      defaultDecimals: 2,
    ),
    CurrencyOption(
      code: 'SAR',
      name: 'Saudi Riyal',
      symbol: 'SAR',
      defaultIndianGrouping: false,
      defaultDecimals: 2,
    ),
    CurrencyOption(
      code: 'CHF',
      name: 'Swiss Franc',
      symbol: 'CHF',
      defaultIndianGrouping: false,
      defaultDecimals: 2,
    ),
    CurrencyOption(
      code: 'CNY',
      name: 'Chinese Yuan',
      symbol: '¥',
      defaultIndianGrouping: false,
      defaultDecimals: 2,
    ),
    CurrencyOption(
      code: 'KRW',
      name: 'South Korean Won',
      symbol: '₩',
      defaultIndianGrouping: false,
      defaultDecimals: 0,
    ),
  ];

  // Available Date Format Presets
  static const List<DateFormatPreset> dateFormatPresets = [
    DateFormatPreset(pattern: 'dd MMM yyyy', label: '06 Oct 2026 (Default)'),
    DateFormatPreset(pattern: 'dd/MM/yyyy', label: '06/10/2026 (DD/MM/YYYY)'),
    DateFormatPreset(pattern: 'MM/dd/yyyy', label: '10/06/2026 (MM/DD/YYYY)'),
    DateFormatPreset(pattern: 'yyyy-MM-dd', label: '2026-10-06 (YYYY-MM-DD)'),
    DateFormatPreset(pattern: 'dd MMMM yyyy', label: '06 October 2026 (Full Month)'),
    DateFormatPreset(pattern: 'EEE, dd MMM yyyy', label: 'Tue, 06 Oct 2026 (With Day)'),
  ];

  AppSettings copyWith({
    int? primaryColorValue,
    ThemeMode? themeMode,
    String? fontFamily,
    double? fontScale,
    String? currencyCode,
    String? currencySymbol,
    bool? symbolBeforeAmount,
    int? decimalDigits,
    bool? useIndianGrouping,
    String? dateFormatPattern,
    bool? is24HourTime,
  }) {
    return AppSettings(
      primaryColorValue: primaryColorValue ?? this.primaryColorValue,
      themeMode: themeMode ?? this.themeMode,
      fontFamily: fontFamily ?? this.fontFamily,
      fontScale: fontScale ?? this.fontScale,
      currencyCode: currencyCode ?? this.currencyCode,
      currencySymbol: currencySymbol ?? this.currencySymbol,
      symbolBeforeAmount: symbolBeforeAmount ?? this.symbolBeforeAmount,
      decimalDigits: decimalDigits ?? this.decimalDigits,
      useIndianGrouping: useIndianGrouping ?? this.useIndianGrouping,
      dateFormatPattern: dateFormatPattern ?? this.dateFormatPattern,
      is24HourTime: is24HourTime ?? this.is24HourTime,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'primaryColorValue': primaryColorValue,
      'themeMode': themeMode.name,
      'fontFamily': fontFamily,
      'fontScale': fontScale,
      'currencyCode': currencyCode,
      'currencySymbol': currencySymbol,
      'symbolBeforeAmount': symbolBeforeAmount,
      'decimalDigits': decimalDigits,
      'useIndianGrouping': useIndianGrouping,
      'dateFormatPattern': dateFormatPattern,
      'is24HourTime': is24HourTime,
    };
  }

  factory AppSettings.fromMap(Map<String, dynamic> map) {
    ThemeMode parsedThemeMode;
    switch (map['themeMode']) {
      case 'dark':
        parsedThemeMode = ThemeMode.dark;
        break;
      case 'system':
        parsedThemeMode = ThemeMode.system;
        break;
      case 'light':
      default:
        parsedThemeMode = ThemeMode.light;
    }

    return AppSettings(
      primaryColorValue: (map['primaryColorValue'] as num?)?.toInt() ?? 0xFF1E40AF,
      themeMode: parsedThemeMode,
      fontFamily: (map['fontFamily'] as String?) ?? 'Inter',
      fontScale: (map['fontScale'] as num?)?.toDouble() ?? 1.0,
      currencyCode: (map['currencyCode'] as String?) ?? 'INR',
      currencySymbol: (map['currencySymbol'] as String?) ?? '₹',
      symbolBeforeAmount: (map['symbolBeforeAmount'] as bool?) ?? true,
      decimalDigits: (map['decimalDigits'] as num?)?.toInt() ?? 2,
      useIndianGrouping: (map['useIndianGrouping'] as bool?) ?? true,
      dateFormatPattern: (map['dateFormatPattern'] as String?) ?? 'dd MMM yyyy',
      is24HourTime: map['is24HourTime'] == true,
    );
  }
}
