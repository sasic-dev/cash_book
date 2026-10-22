import 'package:flutter/material.dart';
import '../../config/app_constants.dart';

export '../../config/app_constants.dart'
    show
        AppColorPreset,
        CurrencyOption,
        DateFormatPreset,
        TimeFormatPreset;

/// Currency conversion helper for exchange rates and conversion calculations
class CurrencyConversionHelper {
  /// Default exchange rates relative to 1 INR base (INR value per 1 unit of currency)
  static Map<String, double> get defaultRatesToInr => AppConstants.defaultRatesToInr;

  /// Converts [amount] from [fromCode] to [toCode] using exchange rates
  static double convert(
    double amount, {
    required String fromCode,
    required String toCode,
    Map<String, double>? ratesToInr,
  }) {
    if (fromCode.toUpperCase() == toCode.toUpperCase()) return amount;
    final rates = ratesToInr ?? defaultRatesToInr;
    final fromRate = rates[fromCode.toUpperCase()] ?? 1.0;
    final toRate = rates[toCode.toUpperCase()] ?? 1.0;
    if (toRate == 0) return 0.0;
    return (amount * fromRate) / toRate;
  }

  /// Returns multiplier factor such that: targetAmount = sourceAmount * factor
  static double getFactor({
    required String fromCode,
    required String toCode,
    Map<String, double>? ratesToInr,
  }) {
    if (fromCode.toUpperCase() == toCode.toUpperCase()) return 1.0;
    final rates = ratesToInr ?? defaultRatesToInr;
    final fromRate = rates[fromCode.toUpperCase()] ?? 1.0;
    final toRate = rates[toCode.toUpperCase()] ?? 1.0;
    if (toRate == 0) return 1.0;
    return fromRate / toRate;
  }

  /// Recovers original canonical INR value from potential floating point
  /// and intermediate 2-decimal foreign conversion drift (e.g. 999.94 -> 1000.0,
  /// 499.97 -> 500.0, 100.34 -> 100.0).
  static double recoverDriftedInrAmount(
    double currentAmount, {
    Map<String, double>? ratesToInr,
  }) {
    if (currentAmount <= 0) return currentAmount;
    final candidateInt = currentAmount.roundToDouble();
    final diffFromInt = (currentAmount - candidateInt).abs();
    if (diffFromInt < 0.0001) {
      return candidateInt;
    }

    final rates = <double>{
      defaultRatesToInr['USD'] ?? AppConstants.defaultUsdRate,
      defaultRatesToInr['EUR'] ?? AppConstants.defaultEurRate,
      if (ratesToInr != null)
        ...ratesToInr.values.where((r) => r > 1.0),
    };

    // 1. Check if candidate integer was converted to foreign and back
    for (final rate in rates) {
      final foreign = double.parse((candidateInt / rate).toStringAsFixed(2));
      final reconstructed = double.parse((foreign * rate).toStringAsFixed(2));
      if ((reconstructed - currentAmount).abs() <= 0.05) {
        return candidateInt;
      }
    }

    // 2. Check if candidate half (e.g. 10.50, 25.50) was converted to foreign and back
    final candidateHalf = (currentAmount * 2).roundToDouble() / 2;
    if ((currentAmount - candidateHalf).abs() > 0.0001) {
      for (final rate in rates) {
        final foreign = double.parse((candidateHalf / rate).toStringAsFixed(2));
        final reconstructed = double.parse((foreign * rate).toStringAsFixed(2));
        if ((reconstructed - currentAmount).abs() <= 0.05) {
          return candidateHalf;
        }
      }
    }

    return double.parse(currentAmount.toStringAsFixed(2));
  }
}

class AppSettings {
  // Theme & Color
  final int primaryColorValue;
  final ThemeMode themeMode;

  // Typography - 4 necessary fonts
  final String fontFamily;
  final double fontScale; // 0.85 to 1.40

  // Currency - 3 formats with conversion, INR is default
  final String currencyCode;
  final String currencySymbol;
  final bool symbolBeforeAmount;
  final int decimalDigits;
  final bool useIndianGrouping;
  final Map<String, double> customExchangeRates;

  // Date & Time - 4 formats each
  final String dateFormatPattern;
  final String timeFormatPattern;
  final bool is24HourTime;

  // User Profile & Account
  final String userName;
  final String? userPhone;
  final String? userUpiId;
  final bool hasCompletedAccountSetup;

  const AppSettings({
    this.primaryColorValue = AppConstants.defaultPrimaryColorValue, // Sapphire Indigo
    this.themeMode = ThemeMode.light,
    this.fontFamily = AppConstants.defaultFontFamily,
    this.fontScale = AppConstants.defaultFontScale,
    this.currencyCode = AppConstants.defaultCurrencyCode,
    this.currencySymbol = AppConstants.defaultCurrencySymbol,
    this.symbolBeforeAmount = AppConstants.defaultSymbolBeforeAmount,
    this.decimalDigits = AppConstants.defaultDecimalDigits,
    this.useIndianGrouping = AppConstants.defaultIndianGrouping,
    this.customExchangeRates = AppConstants.defaultRatesToInr,
    this.dateFormatPattern = AppConstants.defaultDateFormat,
    this.timeFormatPattern = AppConstants.defaultTimeFormat,
    this.is24HourTime = AppConstants.defaultIs24HourTime,
    this.userName = AppConstants.defaultCurrentUserName,
    this.userPhone,
    this.userUpiId,
    this.hasCompletedAccountSetup = AppConstants.defaultAccountSetupCompleted,
  });

  Color get primaryColor => Color(primaryColorValue);

  // Available Color Presets
  static List<AppColorPreset> get colorPresets => AppConstants.colorPresets;

  // Available Font Presets - exactly 4 necessary fonts
  static List<String> get fontPresets => AppConstants.fontPresets;

  // Available Currencies - exactly 3 formats with conversion, INR is default
  static List<CurrencyOption> get presetCurrencies => AppConstants.presetCurrencies;

  // Available Date Format Presets - exactly 4 formats
  static List<DateFormatPreset> get dateFormatPresets => AppConstants.dateFormatPresets;

  // Available Time Format Presets - exactly 4 formats
  static List<TimeFormatPreset> get timeFormatPresets => AppConstants.timeFormatPresets;

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
    Map<String, double>? customExchangeRates,
    String? dateFormatPattern,
    String? timeFormatPattern,
    bool? is24HourTime,
    String? userName,
    String? userPhone,
    String? userUpiId,
    bool? hasCompletedAccountSetup,
  }) {
    final finalTimePattern = timeFormatPattern ??
        (is24HourTime != null
            ? (is24HourTime ? AppConstants.default24HourTimeFormat : AppConstants.defaultTimeFormat)
            : this.timeFormatPattern);
    final finalIs24 = is24HourTime ?? finalTimePattern.startsWith('HH');

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
      customExchangeRates: customExchangeRates ?? this.customExchangeRates,
      dateFormatPattern: dateFormatPattern ?? this.dateFormatPattern,
      timeFormatPattern: finalTimePattern,
      is24HourTime: finalIs24,
      userName: userName ?? this.userName,
      userPhone: userPhone ?? this.userPhone,
      userUpiId: userUpiId ?? this.userUpiId,
      hasCompletedAccountSetup: hasCompletedAccountSetup ?? this.hasCompletedAccountSetup,
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
      'customExchangeRates': customExchangeRates,
      'dateFormatPattern': dateFormatPattern,
      'timeFormatPattern': timeFormatPattern,
      'is24HourTime': is24HourTime,
      'userName': userName,
      'userPhone': userPhone,
      'userUpiId': userUpiId,
      'hasCompletedAccountSetup': hasCompletedAccountSetup,
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

    final is24 = map['is24HourTime'] == true;
    final timePattern = (map['timeFormatPattern'] as String?) ??
        (is24 ? AppConstants.default24HourTimeFormat : AppConstants.defaultTimeFormat);

    final rawRates = map['customExchangeRates'];
    Map<String, double> rates = AppConstants.defaultRatesToInr;
    if (rawRates is Map) {
      rates = rawRates.map((k, v) => MapEntry(k.toString(), (v as num).toDouble()));
    }

    return AppSettings(
      primaryColorValue: (map['primaryColorValue'] as num?)?.toInt() ?? AppConstants.defaultPrimaryColorValue,
      themeMode: parsedThemeMode,
      fontFamily: (map['fontFamily'] as String?) ?? AppConstants.defaultFontFamily,
      fontScale: (map['fontScale'] as num?)?.toDouble() ?? AppConstants.defaultFontScale,
      currencyCode: (map['currencyCode'] as String?) ?? AppConstants.defaultCurrencyCode,
      currencySymbol: (map['currencySymbol'] as String?) ?? AppConstants.defaultCurrencySymbol,
      symbolBeforeAmount: (map['symbolBeforeAmount'] as bool?) ?? AppConstants.defaultSymbolBeforeAmount,
      decimalDigits: (map['decimalDigits'] as num?)?.toInt() ?? AppConstants.defaultDecimalDigits,
      useIndianGrouping: (map['useIndianGrouping'] as bool?) ?? AppConstants.defaultIndianGrouping,
      customExchangeRates: rates,
      dateFormatPattern: (map['dateFormatPattern'] as String?) ?? AppConstants.defaultDateFormat,
      timeFormatPattern: timePattern,
      is24HourTime: timePattern.startsWith('HH') || is24,
      userName: (map['userName'] as String?) ?? AppConstants.defaultCurrentUserName,
      userPhone: map['userPhone'] as String?,
      userUpiId: map['userUpiId'] as String?,
      hasCompletedAccountSetup: (map['hasCompletedAccountSetup'] as bool?) ?? AppConstants.defaultAccountSetupCompleted,
    );
  }
}
