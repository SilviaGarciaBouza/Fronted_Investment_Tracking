import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
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

    test('GET devuelve el cuerpo decodificado en éxito', () async {
      final result = await api.get('/test-get');
      expect(result['result'], 'ok');
    });

    test('POST devuelve el cuerpo en éxito y null en 401', () async {
      final success = await api.post('/test-post', {'dummy': 'data'});
      expect(success['id'], 123);

      final fail = await api.post('/unauthorized', {});
      expect(fail, isNull);
    });

    test('DELETE devuelve true en éxito', () async {
      final deleted = await api.delete('/test-delete');
      expect(deleted, true);
    });
  });
}
