import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:investment_tracking/exceptions/server_http_exception.dart';

/// Determina si un error es debido a una fallo en la comunicación con el servidor.
bool isServerUnavailableError(Object e) =>
    e is SocketException ||
    e is TimeoutException ||
    e is http.ClientException ||
    e is ServerHttpException ||
    e is FormatException;
