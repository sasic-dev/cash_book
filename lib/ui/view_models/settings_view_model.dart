import 'package:flutter/material.dart';
import '../../data/models/app_settings.dart';
import '../../data/services/settings_service.dart';
import '../utils/formatters.dart';

class SettingsViewModel extends ChangeNotifier {
  final SettingsService _service;

  AppSettings _settings = const AppSettings();
  bool _isLoading = true;

  SettingsViewModel({SettingsService? service})
      : _service = service ?? SettingsService();

  AppSettings get settings => _settings;
  bool get isLoading => _isLoading;

  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    _settings = await _service.loadSettings();
    _applyFormatters();

    _isLoading = false;
    notifyListeners();
  }

  void _applyFormatters() {
    AppFormatters.updateCurrency(
      symbol: _settings.currencySymbol,
      decimalDigits: _settings.decimalDigits,
      symbolBeforeAmount: _settings.symbolBeforeAmount,
      useIndianGrouping: _settings.useIndianGrouping,
    );
    AppFormatters.updateDateTimeFormat(
      dateFormatPattern: _settings.dateFormatPattern,
      is24Hour: _settings.is24HourTime,
    );
  }

  Future<void> setPrimaryColor(int colorValue) async {
    _settings = _settings.copyWith(primaryColorValue: colorValue);
    notifyListeners();
    await _service.saveSettings(_settings);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _settings = _settings.copyWith(themeMode: mode);
    notifyListeners();
    await _service.saveSettings(_settings);
  }

  Future<void> setFontFamily(String family) async {
    _settings = _settings.copyWith(fontFamily: family);
    notifyListeners();
    await _service.saveSettings(_settings);
  }

  Future<void> setFontScale(double scale) async {
    final clamped = scale.clamp(0.80, 1.50);
    _settings = _settings.copyWith(fontScale: clamped);
    notifyListeners();
    await _service.saveSettings(_settings);
  }

  Future<void> setCurrency({
    required String code,
    required String symbol,
    required bool symbolBeforeAmount,
    required int decimalDigits,
    required bool useIndianGrouping,
  }) async {
    _settings = _settings.copyWith(
      currencyCode: code,
      currencySymbol: symbol,
      symbolBeforeAmount: symbolBeforeAmount,
      decimalDigits: decimalDigits,
      useIndianGrouping: useIndianGrouping,
    );
    _applyFormatters();
    notifyListeners();
    await _service.saveSettings(_settings);
  }

  Future<void> setDateFormat(String pattern) async {
    _settings = _settings.copyWith(dateFormatPattern: pattern);
    _applyFormatters();
    notifyListeners();
    await _service.saveSettings(_settings);
  }

  Future<void> setTimeFormat(bool is24Hour) async {
    _settings = _settings.copyWith(is24HourTime: is24Hour);
    _applyFormatters();
    notifyListeners();
    await _service.saveSettings(_settings);
  }

  Future<void> resetToDefaults() async {
    _settings = const AppSettings();
    _applyFormatters();
    notifyListeners();
    await _service.saveSettings(_settings);
  }
}
