import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:investment_tracking/dao/user_dao.dart';
import 'package:investment_tracking/database/database_helper.dart';
import 'package:investment_tracking/models/user.dart';
import 'package:investment_tracking/repositories/session_repository.dart';
import 'package:investment_tracking/viewmodels/Inv_viewmodel.dart';
import '../helpers/db_test_helper.dart';
import '../helpers/http_mock.dart';

// SQLite is treated as mocked infrastructure in this file:
// setUpDatabase() is called so internal DAO operations don't throw,
// but no test asserts SQLite state. All assertions are on ViewModel state.

Map<String, dynamic> _btcItemJson() => {
  'id': 10,
  'name': 'BTCUSDT',
  'category': {'id': 1, 'name': 'Crypto'},
  'currentPrice': 50000.0,
  'transactions': [
    {
      'id': 5,
      'stocks': 1.0,
      'purchasePrice': 45000.0,
      'invEur': 45000.0,
      'purchaseDate': '2024-01-15T00:00:00.000',
    },
  ],
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await setUpDatabase();
    HttpOverrides.global = MockHttpOverrides((url) async {
      if (url.path.contains('/users/login')) {
        return MockHttpResponse(
          json.encode({
            'token': 'tok',
            'user': {'id': 1, 'username': 'alice', 'email': 'a@b.com'},
          }),
        );
      }
      if (url.path.contains('/users/health')) {
        return MockHttpResponse('ok');
      }
      if (url.path.contains('/items/user/1')) {
        return MockHttpResponse(json.encode([_btcItemJson()]));
      }
      return MockHttpResponse('[]');
    });
  });
  tearDownAll(tearDownDatabase);

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await clearAllTables();
    // Seed category as FK infrastructure so saveItems() doesn't throw
    final db = await DatabaseHelper.instance.database;
    await db.insert('categories', {'id': 1, 'name': 'Crypto'});
  });

  // ─── Level 1: ViewModel state ─────────────────────────────────────────────
  group('Level 1 — ViewModel state after login', () {
    test('login sets currentUser with server data', () async {
      final vm = InvViewModel();
      final success = await vm.login('alice', '1234');

      expect(success, isTrue);
      expect(vm.currentUser, isNotNull);
      expect(vm.currentUser!.username, 'alice');
      expect(vm.currentUser!.token, 'tok');
      expect(vm.isOnline, isTrue);
    });
  });

  // ─── Level 2: ViewModel + SessionRepository ───────────────────────────────
  group('Level 2 — ViewModel + SessionRepository (SharedPreferences)', () {
    test(
      'login persists userId in SharedPreferences via SessionRepository',
      () async {
        final vm = InvViewModel();
        await vm.login('alice', '1234');

        final sessionId = await SessionRepository().getUserId();
        expect(sessionId, 1);
      },
    );
  });

  // ─── Level 3: Full session-restore path ──────────────────────────────────
  // checkLocalSession was removed; the restore path is now loadUserSession() +
  // fetchItems(), which together cover the same ViewModel → Repository → DAO chain.
  group('Level 3 — Full session restore path (loadUserSession + fetchItems)', () {
    test(
      'loadUserSession loads correct user from SQLite and fetchItems populates itemList',
      () async {
        await UserDao().saveUser(
          User(id: 1, username: 'alice', email: 'a@b.com', token: 'tok'),
        );
        SharedPreferences.setMockInitialValues({'current_user_id': '1'});

        final vm = InvViewModel();
        final hasSession = await vm.loadUserSession();

        expect(hasSession, isTrue);
        expect(vm.currentUser, isNotNull);
        expect(vm.currentUser!.username, 'alice');

        await vm.fetchItems();

        expect(vm.itemList.length, 1);
        expect(vm.isOnline, isTrue);
      },
    );

    test(
      'loadUserSession returns false when userId is not in SharedPreferences',
      () async {
        final vm = InvViewModel();
        expect(await vm.loadUserSession(), isFalse);
        expect(vm.currentUser, isNull);
      },
    );
  });
}
