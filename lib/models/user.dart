/// Representa al usuario autenticado.
///
/// Se utiliza en el [AuthService] para gestionar el token JWT y
/// en el [UserRepository] para persistir el perfil básico localmente.
class User {
  final int id;
  final String username;
  final String email;
  final String token;

  User({
    required this.id,
    required this.username,
    required this.email,
    required this.token,
  });

  /// Crea un usuario desde la respuesta DTO del backend.
  factory User.fromJson(Map<String, dynamic> json) {
    // Maneja tanto si el JSON viene con el nodo 'user' o directo
    final userData = json['user'] ?? json;
    return User(
      id: userData['id'] ?? 0,
      username: userData['username'] ?? '',
      email: userData['email'] ?? '',
      token: json['token'] ?? '',
    );
  }
}
