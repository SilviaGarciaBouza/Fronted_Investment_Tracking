import '../models/user.dart';
import '../service/api_service.dart';

/// Repositorio encargado de la gestion de sesiones y autenticacion.
class AuthRepository {
  final ApiService _apiService = ApiService();

  /// Envia las credenciales al servidor para iniciar sesion.
  /// Retorna un objeto User si la autenticacion es exitosa o null si falla.
  Future<User?> login(String username, String password) async {
    try {
      final response = await _apiService.post('/users/login', {
        "username": username,
        "password": password,
      });
      print(response);
      if (response != null) {
        return User.fromJson(response['user']);
      }
    } catch (e) {
      print("Error en login: $e");
    }
    return null;
  }

  /// Registra un nuevo usuario en la base de datos MariaDB.
  Future<bool> register(String username, String password, String email) async {
    try {
      final data = await _apiService.post('/users/register', {
        "username": username,
        "password": password,
        "email": email,
      });
      return data != null;
    } catch (e) {
      return false;
    }
  }
}
