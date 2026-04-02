import '../models/user.dart';
import '../service/api_service.dart';
import '../dao/user_dao.dart';

/// Gestiona la autenticación y la persistencia de la sesión.
class AuthRepository {
  final ApiService _apiService = ApiService();
  final UserDao _userDao = UserDao();

  /// Realiza el login, guarda el usuario en SQLite y devuelve el objeto [User].
  Future<User?> login(String username, String password) async {
    try {
      final response = await _apiService.post('/users/login', {
        "username": username,
        "password": password,
      });

      if (response != null) {
        final user = User.fromJson(response);
        // Persistencia local de la sesión
        await _userDao.saveUser(user);
        return user;
      }
    } catch (e) {
      print("Error Auth: $e");
    }
    return null;
  }

  /// Registra un nuevo usuario en MariaDB.
  Future<bool> register(String username, String password, String email) async {
    try {
      final data = await _apiService.post('/users/register', {
        "username": username,
        "password": password,
        "email": email,
      });
      return data != null;
    } catch (e) {
      print("Error en Registro Repository: $e");
      return false;
    }
  }
}
