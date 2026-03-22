import '../models/user.dart';
import '../service/api_service.dart';

/// Repositorio encargado de la gestión de sesiones y autenticación de usuarios.
///
/// Actúa como intermediario entre el servicio de red y la lógica de negocio de la App.
class AuthRepository {
  final ApiService _apiService = ApiService();

  /// Envía las credenciales al servidor MariaDB para iniciar sesión.
  ///
  /// Retorna un objeto [User] con su token si el login es correcto, o null en caso de error.
  Future<User?> login(String username, String password) async {
    try {
      final response = await _apiService.post('/users/login', {
        "username": username,
        "password": password,
      });

      if (response != null && response['user'] != null) {
        final userData = Map<String, dynamic>.from(response['user']);
        userData['token'] = response['token'];

        return User.fromJson(userData);
      }
    } catch (e) {
      print("Error en login: $e");
    }
    return null;
  }

  /// Registra una nueva cuenta de usuario en el servidor.
  ///
  /// Devuelve true si el registro fue exitoso.
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
