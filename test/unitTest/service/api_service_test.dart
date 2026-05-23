import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:investment_tracking/exceptions/Unauthorized_exception.dart';
import 'package:investment_tracking/service/api_service.dart';
import '../../helpers/http_mock.dart';

void main() {
  setUpAll(() {
    HttpOverrides.global = MockHttpOverrides((url) async {
      if (url.path.contains('test-get')) {
        return MockHttpResponse(json.encode({'result': 'ok'}));
      } else if (url.path.contains('test-post')) {
        return MockHttpResponse(json.encode({'id': 123}), 201);
      } else if (url.path.contains('unauthorized')) {
        return MockHttpResponse('', 401);
      } else if (url.path.contains('test-delete')) {
        return MockHttpResponse('');
      }
      return MockHttpResponse('[]');
    });
  });

  group('ApiService', () {
    final api = ApiService();

    test('GET returns decoded body on success', () async {
      final result = await api.get('/test-get');
      expect(result['result'], 'ok');
    });

    test('POST throws UnauthorizedException on 401', () async {
      final success = await api.post('/test-post', {'dummy': 'data'});
      expect(success['id'], 123);

      expect(
        () => api.post('/unauthorized', {}),
        throwsA(isA<UnauthorizedException>()),
      );
    });

    test('DELETE returns true on success', () async {
      final deleted = await api.delete('/test-delete');
      expect(deleted, true);
    });
  });
}
