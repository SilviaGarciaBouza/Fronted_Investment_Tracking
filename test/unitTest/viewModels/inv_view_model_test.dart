import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:investment_tracking/database/database_helper.dart';
import 'package:investment_tracking/viewmodels/InvViewModel.dart';
import 'package:investment_tracking/models/category.dart';
import 'package:investment_tracking/models/item.dart';
import 'package:investment_tracking/models/transaction.dart';
import '../../helpers/db_test_helper.dart';
import '../../helpers/http_mock.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    HttpOverrides.global = MockHttpOverrides((url) async {
      if (url.path.contains('/users/login')) {
        return MockHttpResponse(
          json.encode({
            'token': 'tok',
            'user': {'id': 1, 'username': 'alice', 'email': 'a@b.com'},
          }),
        );
      }
      if (url.path.contains('/users/register')) {
        return MockHttpResponse(json.encode({'message': 'ok'}), 201);
      }
      if (url.path.contains('/users/health')) {
        return MockHttpResponse('ok');
      }
      if (url.path.contains('/categories')) {
        return MockHttpResponse(
          json.encode([
            {'id': 1, 'name': 'Crypto'},
          ]),
        );
      }
      return MockHttpResponse('[]');
    });
    await setUpDatabase();
  });

  tearDownAll(tearDownDatabase);

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await clearAllTables();
  });
  tearDown(clearAllTables);

  group('InvViewModel: computed getters', () {
    test('totalCurrentValue is 0 when there are no transactions', () {
      final vm = InvViewModel();
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

    test('totalInvestment, totalPnL and totalPnLPercent with real data', () {
      final vm = InvViewModel();
      vm.itemList = [
        Item(
          name: 'BTC',
          category: Category(id: 1, name: 'Crypto'),
          currentPrice: 60000.0,
          transactions: [
            Transaction(
              stocks: 1.0,
              purchasePrice: 40000.0,
              invEur: 40000.0,
              purchaseDate: DateTime(2026, 1, 1),
            ),
          ],
        ),
      ];
      expect(vm.totalInvestment, 40000.0);
      expect(vm.totalPnL, 20000.0);
      expect(vm.totalPnLPercent, 50.0);
    });

    test(
      'totalPnLPercent is 0 when there is no investment (avoids division by zero)',
      () {
        expect(InvViewModel().totalPnLPercent, 0.0);
      },
    );

    test(
      'allTransactions aggregates transactions from all items sorted by date descending',
      () {
        final vm = InvViewModel();
        final cat = Category(id: 1, name: 'Test');
        vm.itemList = [
          Item(
            name: 'A',
            category: cat,
            currentPrice: 10,
            transactions: [
              Transaction(
                stocks: 1,
                purchasePrice: 10,
                invEur: 10,
                purchaseDate: DateTime(2026, 1, 1),
              ),
            ],
          ),
          Item(
            name: 'B',
            category: cat,
            currentPrice: 20,
            transactions: [
              Transaction(
                stocks: 2,
                purchasePrice: 20,
                invEur: 40,
                purchaseDate: DateTime(2026, 6, 1),
              ),
            ],
          ),
        ];
        final all = vm.allTransactions;
        expect(all.length, 2);
        expect(all.first.purchaseDate, DateTime(2026, 6, 1));
      },
    );
  });

  group('InvViewModel: preferences', () {
    test('toggleTheme toggles isDarkMode and persists it', () async {
      final vm = InvViewModel();
      final before = vm.isDarkMode;
      vm.toggleTheme();
      expect(vm.isDarkMode, !before);

      final vm2 = InvViewModel();
      await vm2.initSettings();
      expect(vm2.isDarkMode, !before);
    });

    test('setLanguage updates currentLocale and persists it', () async {
      final vm = InvViewModel();
      vm.setLanguage('gl');
      expect(vm.currentLocale, 'gl');

      final vm2 = InvViewModel();
      await vm2.initSettings();
      expect(vm2.currentLocale, 'gl');
    });

    test(
      'initSettings loads system values when no preferences are stored',
      () async {
        final vm = InvViewModel();
        await vm.initSettings();
        expect(vm.isDarkMode, isFalse);
        expect(['es', 'gl', 'en'].contains(vm.currentLocale), isTrue);
      },
    );
  });

  group('InvViewModel: session', () {
    test('logout clears currentUser, itemList and categories', () async {
      final vm = InvViewModel();
      vm.itemList = [
        Item(
          name: 'X',
          category: Category(id: 1, name: ''),
          currentPrice: 0,
          transactions: [],
        ),
      ];

      await vm.logout();

      expect(vm.currentUser, isNull);
      expect(vm.itemList, isEmpty);
      expect(vm.categories, isEmpty);
    });

    test(
      'loadUserSession returns false when no session is stored',
      () async {
        expect(await InvViewModel().loadUserSession(), isFalse);
      },
    );

    test(
      'loadUserSession returns true when userId is in SharedPreferences',
      () async {
        SharedPreferences.setMockInitialValues({'current_user_id': '42'});
        expect(await InvViewModel().loadUserSession(), isTrue);
      },
    );

    test(
      'checkLocalSession returns true and sets currentUser when user is in SQLite',
      () async {
        final db = await DatabaseHelper.instance.database;
        await db.insert('users', {
          'username': 'alice',
          'email': 'a@b.com',
          'token': 'tok',
        });

        final vm = InvViewModel();
        final result = await vm.checkLocalSession();

        expect(result, isTrue);
        expect(vm.currentUser?.username, 'alice');
      },
    );

    test(
      'checkLocalSession returns false when no user is in SQLite',
      () async {
        expect(await InvViewModel().checkLocalSession(), isFalse);
      },
    );
  });

  group('InvViewModel: authentication', () {
    test(
      'login returns true, sets currentUser and marks isOnline',
      () async {
        final vm = InvViewModel();
        final success = await vm.login('alice', '1234');

        expect(success, isTrue);
        expect(vm.currentUser?.username, 'alice');
        expect(vm.currentUser?.token, 'tok');
        expect(vm.isOnline, isTrue);
      },
    );

    test('register returns true when server responds with 201', () async {
      expect(
        await InvViewModel().register('nuevo', '1234', 'nuevo@test.com'),
        isTrue,
      );
    });
  });

  group('InvViewModel: data loading', () {
    test(
      'fetchCategories populates the list when user is active',
      () async {
        final vm = InvViewModel();
        await vm.login('alice', '1234');

        await vm.fetchCategories();

        expect(vm.categories, isNotEmpty);
        expect(vm.categories.first.name, 'Crypto');
      },
    );

    test('fetchCategories does nothing when no user is active', () async {
      final vm = InvViewModel();

      await vm.fetchCategories();

      expect(vm.categories, isEmpty);
    });
  });
}
