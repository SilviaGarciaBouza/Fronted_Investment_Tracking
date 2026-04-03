import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const String _langKey = "app_lang";
  static const String _themeKey = "app_is_dark";

  /// Guardar idioma
  Future<void> saveLanguage(String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_langKey, code);
  }

  // Leer idioma (devuelve null si es la primera vez)
  Future<String?> getLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_langKey);
  }

  /// Guardar tema
  Future<void> saveTheme(bool isDark) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themeKey, isDark);
  }

  /// Leer tema (devuelve null si es la primera vez)
  Future<bool?> getTheme() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_themeKey);
  }
}
