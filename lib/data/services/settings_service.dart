import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/app_constants.dart';
import '../models/app_settings.dart';

/// Abstract contract for app settings persistence.
/// Follows Dependency Inversion Principle (DIP).
abstract class ISettingsService {
  Future<AppSettings> loadSettings();
  Future<void> saveSettings(AppSettings settings);
  Future<void> clearSettings();
}

class SettingsService implements ISettingsService {
  static const String _settingsKey = AppConstants.keySettings;

  @override
  Future<AppSettings> loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? jsonStr = prefs.getString(_settingsKey);
      if (jsonStr == null || jsonStr.isEmpty) {
        return const AppSettings();
      }
      final Map<String, dynamic> decoded =
          jsonDecode(jsonStr) as Map<String, dynamic>;
      return AppSettings.fromMap(decoded);
    } catch (_) {
      return const AppSettings();
    }
  }

  @override
  Future<void> saveSettings(AppSettings settings) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_settingsKey, jsonEncode(settings.toMap()));
    } catch (_) {
      // Ignore storage errors or fallback
    }
  }

  @override
  Future<void> clearSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_settingsKey);
    } catch (_) {
      // Ignore
    }
  }
}
