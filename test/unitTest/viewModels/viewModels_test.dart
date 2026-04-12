import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:investment_tracking/viewmodels/InvViewModel.dart';
import 'package:investment_tracking/models/item.dart';
import 'package:investment_tracking/models/category.dart';

class GlobalHttpInterceptor extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) => _MockHttpClient();
}

class _MockHttpClient extends Fake implements HttpClient {
  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) async =>
      _MockRequest(url);
  @override
  Future<HttpClientRequest> postUrl(Uri url) async => _MockRequest(url);
  @override
  Future<HttpClientRequest> getUrl(Uri url) async => _MockRequest(url);
  @override
  void close({bool force = false}) {}

  @override
  set autoUncompress(bool autoUncompress) {}
}

class _MockRequest extends Fake implements HttpClientRequest {
  final Uri url;
  _MockRequest(this.url);

  @override
  bool followRedirects = true;
  @override
  int maxRedirects = 5;
  @override
  int contentLength = -1;
  @override
  bool persistentConnection = true;

  @override
  HttpHeaders get headers => _MockHeaders();

  @override
  void add(List<int> data) {}
  @override
  void write(Object? object) {}
  @override
  Future addStream(Stream<List<int>> stream) async {}

  @override
  Future<HttpClientResponse> close() async {
    String responseBody = "[]";
    if (url.path.contains('/login')) {
      responseBody = json.encode({
        "token": "test_token",
        "user": {"id": 1, "username": "silvia", "email": "s@t.com"},
      });
    } else if (url.path.contains('/items') ||
        url.path.contains('/categories')) {
      responseBody = "[]";
    }
    return _MockResponse(responseBody);
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
  ContentType? contentType;
}

class _MockResponse extends Fake implements HttpClientResponse {
  final String body;
  _MockResponse(this.body);

  @override
  int get statusCode => 200;

  @override
  String get reasonPhrase => "OK";

  @override
  HttpHeaders get headers => _MockHeaders();

  @override
  int get contentLength => utf8.encode(body).length;

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return Stream.value(utf8.encode(body)).listen(onData);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    HttpOverrides.global = GlobalHttpInterceptor();
    SharedPreferences.setMockInitialValues({});
  });

  group('InvViewModel: Suite de Pruebas Corregida', () {
    late InvViewModel vm;

    setUp(() {
      vm = InvViewModel();
    });

    test('1. Cálculos: totalCurrentValue debe ser 0 sin transacciones', () {
      vm.itemList = [
        Item(
          name: 'A',
          currentPrice: 100,
          category: Category(id: 1, name: ''),
          transactions: [],
        ),
      ];
      expect(vm.totalCurrentValue, 0.0);
    });

    test('2. Preferencias: toggleTheme y setLanguage', () {
      bool currentTheme = vm.isDarkMode;
      vm.toggleTheme();
      expect(vm.isDarkMode, !currentTheme);

      vm.setLanguage('gl');

      expect(vm.currentLocale, 'gl');
    });

    test('3. Logout: Debe limpiar el estado', () async {
      await vm.logout();

      expect(vm.currentUser, isNull);

      expect(vm.itemList, isEmpty);
    });
  });
}
