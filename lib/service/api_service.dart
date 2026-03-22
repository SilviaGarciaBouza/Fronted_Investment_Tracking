import 'dart:convert';
import 'package:http/http.dart' as http;

/// Servicio base para la comunicación con la API REST de Spring Boot.
///
/// Gestiona las cabeceras de autenticación y la serialización JSON para
/// todas las peticiones HTTP (GET, POST, DELETE).
class ApiService {
  /// URL base del servidor.
  final String baseUrl = "http://localhost:8080/api";
  //final String baseUrl = "http://10.0.2.2:8080/api";

  /// Genera las cabeceras necesarias para la petición.
  ///
  /// Incluye el Token JWT en formato Bearer si el usuario está autenticado.
  Map<String, String> _getHeaders(String? token) {
    return {
      "Content-Type": "application/json",
      "Accept": "application/json",
      if (token != null) "Authorization": "Bearer $token",
    };
  }

  /// Realiza una petición GET para obtener recursos del servidor.
  Future<dynamic> get(String endpoint, {String? token}) async {
    final response = await http.get(
      Uri.parse('$baseUrl$endpoint'),
      headers: _getHeaders(token),
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Error GET: ${response.statusCode}');
    }
  }

  /// Realiza una petición POST enviando un cuerpo en formato JSON.
  ///
  /// Retorna null si el servidor responde con 401 (No autorizado).
  Future<dynamic> post(
    String endpoint,
    Map<String, dynamic> data, {
    String? token,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: _getHeaders(token),
      body: json.encode(data),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return json.decode(response.body);
    } else if (response.statusCode == 401) {
      return null;
    } else {
      throw Exception('Error POST: ${response.statusCode}');
    }
  }

  /// Realiza una petición DELETE para eliminar un recurso remoto.
  Future<bool> delete(String endpoint, {String? token}) async {
    final response = await http.delete(
      Uri.parse('$baseUrl$endpoint'),
      headers: _getHeaders(token),
    );
    return response.statusCode == 200 || response.statusCode == 204;
  }
}
