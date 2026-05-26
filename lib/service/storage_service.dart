import 'package:shared_preferences/shared_preferences.dart';

/// Servicio de almacenamiento local
class StorageService {
  /// Guarda un par clave-valor
  Future<void> write(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  /// Lee un par clave-valor
  Future<String?> read(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key);
  }

  /// Elimina un par clave-valor
  Future<void> delete(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
  }
}
