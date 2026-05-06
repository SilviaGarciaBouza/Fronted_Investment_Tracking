import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:investment_tracking/repositories/auth_repository.dart';
import '../../helpers/db_test_helper.dart';
import '../../helpers/http_mock.dart';

void main() {
  setUpAll(() async {
    HttpOverrides.global = MockHttpOverrides((url) async {
      if (url.path.contains('/users/login')) {
        return MockHttpResponse(json.encode({
          'token': 'token_abc',
          'user': {'id': 1, 'username': 'silvia', 'email': 's@t.com'},
        }));
      } else if (url.path.contains('/users/register')) {
        return MockHttpResponse(json.encode({'message': 'ok'}), 201);
      } else if (url.path.contains('/users/health')) {
        return MockHttpResponse('ok');
      }
      return MockHttpResponse('[]');
    });
    await setUpDatabase();
  });

  tearDownAll(tearDownDatabase);
  setUp(clearAllTables);
  tearDown(clearAllTables);

  group('AuthRepository', () {
    test('login returns a valid user with token', () async {
      final user = await AuthRepository().login('silvia', '1234');

      expect(user, isNotNull);
      expect(user?.token, 'token_abc');
      expect(user?.username, 'silvia');
    });

    test('register returns true when server responds with success', () async {
      final result =
          await AuthRepository().register('nuevo', '1234', 'nuevo@test.com');

      expect(result, true);
    });

    test('checkConnection returns true when server is reachable', () async {
      expect(await AuthRepository().checkConnection(), true);
    });
  });
}
