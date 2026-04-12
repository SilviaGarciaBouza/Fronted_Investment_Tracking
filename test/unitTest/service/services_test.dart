import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:investment_tracking/service/api_service.dart';
import 'package:investment_tracking/service/SettingsService.dart';

class ServiceHttpMock extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) => _MockHttpClient();
}

class _MockHttpClient extends Fake implements HttpClient {
  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) async =>
      _MockRequest(url);
  @override
  void close({bool force = false}) {}
}

class _MockRequest extends Fake implements HttpClientRequest {
  final Uri url;
  _MockRequest(this.url);

  @override
  HttpHeaders get headers => _MockHeaders();
  @override
  bool followRedirects = true;
  @override
  int maxRedirects = 5;
  @override
  int contentLength = -1;
  @override
  bool persistentConnection = true;

  @override
  void add(List<int> data) {}
  @override
  void write(Object? object) {}

  @override
  Future addStream(Stream<List<int>> stream) async =>
      stream.listen((_) {}).asFuture();

  @override
  Future<HttpClientResponse> close() async {
    String responseBody = "[]";
    int status = 200;

    if (url.path.contains('test-get')) {
      responseBody = json.encode({"result": "ok"});
    } else if (url.path.contains('test-post')) {
      responseBody = json.encode({"id": 123});
      status = 201;
    } else if (url.path.contains('unauthorized')) {
      status = 401;
    } else if (url.path.contains('test-delete')) {
      status = 200;
      responseBody = "";
    }

    return _MockResponse(responseBody, status);
  }
}

class _MockHeaders extends Fake implements HttpHeaders {
  @override
  void forEach(void Function(String name, List<String> values) f) {}
  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) {}
  @override
  void add(String name, Object value, {bool preserveHeaderCase = false}) {}
  @override
  List<String>? operator [](String name) => [];
}

class _MockResponse extends Fake implements HttpClientResponse {
  final String body;
  @override
  final int statusCode;
  _MockResponse(this.body, this.statusCode);

  @override
  String get reasonPhrase => "OK";
  @override
  bool get isRedirect => false;
  @override
  List<RedirectInfo> get redirects => [];
  @override
  HttpHeaders get headers => _MockHeaders();
  @override
  int get contentLength => utf8.encode(body).length;
  @override
  bool get persistentConnection => true;

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return Stream.value(utf8.encode(body)).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError ?? false,
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    HttpOverrides.global = ServiceHttpMock();
  });

  group('Servicio 1: ApiService', () {
    final api = ApiService();

    test('GET: Éxito', () async {
      final result = await api.get('/test-get');
      expect(result['result'], 'ok');
    });

    test('POST: Éxito y 401', () async {
      final success = await api.post('/test-post', {"dummy": "data"});
      expect(success['id'], 123);

      final fail = await api.post('/unauthorized', {});
      expect(fail, isNull);
    });

    test('DELETE: Éxito', () async {
      final deleted = await api.delete('/test-delete');
      expect(deleted, true);
    });
  });
  group('Servicio 2: SettingsService', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('Debe persistir y recuperar el idioma', () async {
      final settings = SettingsService();

      await settings.saveLanguage('gl');
      final lang = await settings.getLanguage();
      expect(lang, 'gl');
    });

    test('Debe persistir y recuperar el tema (oscuro/claro)', () async {
      final settings = SettingsService();

      await settings.saveTheme(true);
      final isDark = await settings.getTheme();
      expect(isDark, true);
    });

    test('Debe devolver null si no hay nada guardado', () async {
      final settings = SettingsService();
      expect(await settings.getLanguage(), isNull);
      expect(await settings.getTheme(), isNull);
    });
  });
}
