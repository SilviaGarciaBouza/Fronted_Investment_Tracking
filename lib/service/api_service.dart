import 'dart:convert';
import 'package:http/http.dart' as http;

/// Servicio base para la comunicacion con la API REST de Spring Boot.
class ApiService {
  final String baseUrl = "http://localhost:8080/api";
  //final String baseUrl = "http://10.0.2.2:8080/api";

  /// Realiza una peticion GET para obtener datos del servidor.
  Future<dynamic> get(String endpoint) async {
    final response = await http.get(Uri.parse('$baseUrl$endpoint'));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Error GET: ${response.statusCode}');
    }
  }

  /// Realiza una peticion POST enviando un cuerpo en formato JSON.
  /// Maneja especificamente el error 401 para credenciales incorrectas.
  Future<dynamic> post(String endpoint, Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl$endpoint'),

      headers: {"Content-Type": "application/json"},
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

  /// Realiza una petición DELETE para eliminar un recurso.
  Future<bool> delete(String endpoint) async {
    final response = await http.delete(Uri.parse('$baseUrl$endpoint'));
    if (response.statusCode == 200 || response.statusCode == 204) {
      return true;
    } else {
      throw Exception('Error DELETE: ${response.statusCode}');
    }
  }
}
