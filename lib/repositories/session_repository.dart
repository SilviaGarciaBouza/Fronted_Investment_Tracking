import 'package:investment_tracking/service/storage_service.dart';

/// Repositorio encargado de la gestión del estado de la sesión local.
/// Utiliza [StorageService] (generalmente implementado sobre Flutter Secure Storage)
/// para proteger información sensible de la sesión, en este caso el ID del usuario.
class SessionRepository {
  final StorageService _storageService = StorageService();
  static const _userKey = 'current_user_id';

  /// Guarda de forma segura el identificador único del usuario en el almacenamiento persistente.
  Future<void> saveUserId(int userId) async {
    await _storageService.write(_userKey, userId.toString());
  }

  /// Recupera el identificador del usuario de la sesión actual.
  /// Retorna un [int] con el ID si existe, o `null` si no se ha iniciado sesión
  /// o si el dato no es un entero válido.
  Future<int?> getUserId() async {
    final jsonString = await _storageService.read(_userKey);
    if (jsonString == null) return null;
    return int.tryParse(jsonString);
  }

  /// Destruye la sesión actual eliminando el identificador del usuario del almacenamiento.
  Future<void> clearUserId() async {
    await _storageService.delete(_userKey);
  }
}
