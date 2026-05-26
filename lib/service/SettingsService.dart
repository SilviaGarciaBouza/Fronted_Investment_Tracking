import 'package:shared_preferences/shared_preferences.dart';

/// Servicio de configuración
class SettingsService {
  static const String _langKey = "app_lang";
  static const String _themeKey = "app_is_dark";

  /// Guarda el codigo del idioma
  Future<void> saveLanguage(String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_langKey, code);
  }

  // Lee idioma (devuelve null si es la primera vez)
  Future<String?> getLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_langKey);
  }

  /// Guarda el tema
  Future<void> saveTheme(bool isDark) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themeKey, isDark);
  }

  /// Leer el tema (devuelve null si es la primera vez)
  Future<bool?> getTheme() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_themeKey);
  }
}
