import 'dart:convert';
import 'package:http/http.dart' as http;

/// Servicio central de comunicaciones HTTP.
///
/// Gestiona las peticiones al backend de Spring Boot, centralizando el manejo
/// de cabeceras, el Token JWT y la serialización JSON.
class ApiService {
  /// URL base para el emulador de Android .
  //final String baseUrl = "http://10.0.2.2:8080/api";
  final String baseUrl = "http://localhost:8080/api";
  /*static String get baseUrl {
    if (kIsWeb) {
      return "http://localhost:8080/api";
    } else if (Platform.isAndroid) {
      return "http://10.0.2.2:8080/api";
    } else {
      return "http://localhost:8080/api";
    }
  }*/

  /// Genera las cabeceras estándar, incluyendo el Token Bearer si existe.
  Map<String, String> _getHeaders(String? token) => {
    "Content-Type": "application/json",
    "Accept": "application/json",
    if (token != null) "Authorization": "Bearer $token",
  };

  /// Realiza una petición GET. Lanza una excepción si el servidor falla.
  Future<dynamic> get(String endpoint, {String? token}) async {
    final response = await http.get(
      Uri.parse('$baseUrl$endpoint'),
      headers: _getHeaders(token),
    );
    if (response.statusCode == 200) return json.decode(response.body);
    throw Exception('Error en GET $endpoint: ${response.statusCode}');
  }

  /// Realiza una petición POST. Retorna el cuerpo decodificado o null si hay error 401.
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
    }
    throw Exception('Error en POST $endpoint: ${response.statusCode}');
  }

  /// Realiza una petición DELETE y retorna true si fue exitosa.
  Future<bool> delete(String endpoint, {String? token}) async {
    final response = await http.delete(
      Uri.parse('$baseUrl$endpoint'),
      headers: _getHeaders(token),
    );
    return response.statusCode == 200 || response.statusCode == 204;
  }
}
