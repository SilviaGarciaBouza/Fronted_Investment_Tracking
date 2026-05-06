import 'package:flutter_test/flutter_test.dart';
import 'package:investment_tracking/models/user.dart';

void main() {
  group('User: serialization and mapping', () {
    test('fromJson maps token and user data correctly', () {
      final json = {
        'token': 'jwt_secret_token',
        'user': {'id': 10, 'username': 'admin', 'email': 'admin@test.com'},
      };

      final user = User.fromJson(json);

      expect(user.id, 10);
      expect(user.username, 'admin');
      expect(user.token, 'jwt_secret_token');
    });

    test('fromJson accepts both nested (API) and flat (cache) JSON', () {
      final jsonAnidado = {
        'token': 'abc',
        'user': {'id': 1, 'username': 'lucia', 'email': 'l@test.com'},
      };
      final user1 = User.fromJson(jsonAnidado);
      expect(user1.username, 'lucia');
      expect(user1.token, 'abc');

      final jsonPlano = {
        'id': 2,
        'username': 'pepe',
        'email': 'p@test.com',
        'token': 'xyz',
      };
      final user2 = User.fromJson(jsonPlano);
      expect(user2.username, 'pepe');
      expect(user2.token, 'xyz');
    });
  });
}
