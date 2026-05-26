/// Representa al usuario autenticado.
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
  /// Extrae los campos dinámicamente si vienen anidados o en la raíz.
  factory User.fromJson(Map<String, dynamic> json) {
    final userData = json['user'] ?? json;
    return User(
      id: userData['id'] ?? 0,
      username: userData['username'] ?? '',
      email: userData['email'] ?? '',
      token: json['token'] ?? '',
    );
  }
}
