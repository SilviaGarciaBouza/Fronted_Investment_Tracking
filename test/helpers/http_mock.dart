import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

/// Callback that receives the request URL and returns a mocked response.
/// Define the URL-routing logic inline per test file.
///
/// Example:
///   HttpOverrides.global = MockHttpOverrides((url) async {
///     if (url.path.contains('/login')) {
///       return MockHttpResponse(json.encode({'token': 'abc', 'user': {...}}));
///     }
///     return MockHttpResponse('[]');
///   });
typedef HttpResponseBuilder = Future<HttpClientResponse> Function(Uri url);

class MockHttpOverrides extends HttpOverrides {
  final HttpResponseBuilder _builder;
  MockHttpOverrides(this._builder);

  @override
  HttpClient createHttpClient(SecurityContext? context) =>
      _MockHttpClient(_builder);
}

class _MockHttpClient extends Fake implements HttpClient {
  final HttpResponseBuilder _builder;
  _MockHttpClient(this._builder);

  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) async =>
      _MockRequest(url, _builder);
  @override
  Future<HttpClientRequest> postUrl(Uri url) async =>
      _MockRequest(url, _builder);
  @override
  Future<HttpClientRequest> getUrl(Uri url) async =>
      _MockRequest(url, _builder);
  @override
  set autoUncompress(bool v) {}
  @override
  void close({bool force = false}) {}
}

class _MockRequest extends Fake implements HttpClientRequest {
  final Uri url;
  final HttpResponseBuilder _builder;
  _MockRequest(this.url, this._builder);

  @override
  HttpHeaders get headers => MockHttpHeaders();
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
  Future<HttpClientResponse> close() => _builder(url);
}

class MockHttpHeaders extends Fake implements HttpHeaders {
  @override
  void forEach(void Function(String name, List<String> values) f) {}
  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) {}
  @override
  void add(String name, Object value, {bool preserveHeaderCase = false}) {}
  @override
  List<String>? operator [](String name) => [];
}

class MockHttpResponse extends Fake implements HttpClientResponse {
  final String body;
  final int _status;
  MockHttpResponse(this.body, [this._status = 200]);

  @override
  int get statusCode => _status;
  @override
  String get reasonPhrase => 'OK';
  @override
  bool get isRedirect => false;
  @override
  List<RedirectInfo> get redirects => [];
  @override
  HttpHeaders get headers => MockHttpHeaders();
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
