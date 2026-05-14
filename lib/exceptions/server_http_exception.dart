class ServerHttpException implements Exception {
  final int statusCode;
  const ServerHttpException(this.statusCode);
}
