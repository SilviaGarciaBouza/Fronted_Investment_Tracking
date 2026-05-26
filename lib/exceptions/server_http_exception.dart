/// Excepción que se lanza cuando el servidor responde con un código de estado de error HTTP
/// (por ejemplo: 400, 404, 500, etc.).
class ServerHttpException implements Exception {
  /// El código de estado HTTP devuelto por el servidor.
  final int statusCode;
  const ServerHttpException(this.statusCode);
}
