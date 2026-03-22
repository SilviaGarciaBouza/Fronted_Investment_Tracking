/// Representa al usuario autenticado en el sistema.
///
/// Almacena el token de sesión necesario para las peticiones al backend.
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

  /// Crea un [User] tras un inicio de sesión exitoso.
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? 0,
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      token: json['token'] ?? '',
    );
  }
}
