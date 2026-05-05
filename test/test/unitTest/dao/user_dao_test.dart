import 'package:flutter_test/flutter_test.dart';
import 'package:investment_tracking/dao/user_dao.dart';
import 'package:investment_tracking/database/database_helper.dart';
import '../../helpers/db_test_helper.dart';

void main() {
  setUpAll(setUpDatabase);
  tearDownAll(tearDownDatabase);
  setUp(clearAllTables);
  tearDown(clearAllTables);

  group('UserDao', () {
    test('insert and get user', () async {
      final db = await DatabaseHelper.instance.database;
      await db.insert('users', {
        'id': 1,
        'username': 'user1',
        'email': 'user1@test.com',
        'token': 'token_ejemplo',
      });

      final user = await UserDao().getUser();

      expect(user, isNotNull);
      expect(user?.username, 'user1');
    });
  });
}
