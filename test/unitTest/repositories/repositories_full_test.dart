import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:investment_tracking/repositories/auth_repository.dart';
import 'package:investment_tracking/repositories/category_repository.dart';
import 'package:investment_tracking/repositories/item_repository.dart';

class GlobalHttpMock extends HttpOverrides {
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
  Future addStream(Stream<List<int>> stream) async {}

  @override
  Future<HttpClientResponse> close() async {
    String responseBody = "[]";
    if (url.path.contains('/login')) {
      responseBody = json.encode({
        "token": "token_abc",
        "user": {"id": 1, "username": "silvia", "email": "s@t.com"},
      });
    } else if (url.path.contains('/categories') ||
        url.path.contains('/items')) {
      responseBody = json.encode([]);
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
  List<String>? operator [](String name) => [];
}

class _MockResponse extends Fake implements HttpClientResponse {
  final String body;
  _MockResponse(this.body);

  @override
  int get statusCode => 200;
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
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;
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

  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    HttpOverrides.global = GlobalHttpMock();

    final db = await openDatabase(inMemoryDatabasePath);
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY,
        username TEXT,
        email TEXT,
        token TEXT
      )
    ''');
  });

  group('Grupo 1: AuthRepository', () {
    test('Login debe devolver un usuario válido', () async {
      final repo = AuthRepository();
      final user = await repo.login('silvia', '1234');

      expect(user, isNotNull);
      expect(user?.token, 'token_abc');
      expect(user?.username, 'silvia');
    });
  });

  group('Grupo 2: CategoryRepository', () {
    test(
      'getAllCategories debe devolver una lista (aunque sea vacía)',
      () async {
        final repo = CategoryRepository();
        final result = await repo.getAllCategories('token');

        expect(result, isA<List>());
      },
    );
  });

  group('Grupo 3: ItemRepository', () {
    test('getLocalItems debe funcionar sin red', () async {
      final repo = ItemRepository();
      final result = await repo.getLocalItems(1);

      expect(result, isA<List>());
    });
  });
}
