import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_settings.dart';

class SettingsService {
  static const String _settingsKey = 'app_settings_v1';

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

  Future<void> saveSettings(AppSettings settings) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_settingsKey, jsonEncode(settings.toMap()));
    } catch (_) {
      // Ignore storage errors or fallback
    }
  }

  Future<void> clearSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_settingsKey);
    } catch (_) {
      // Ignore
    }
  }
}
