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
    test('totalCurrentValue es 0 cuando no hay transacciones', () {
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

    test('totalInvestment, totalPnL y totalPnLPercent con datos reales', () {
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
      'totalPnLPercent es 0 cuando no hay inversión (evita división por cero)',
      () {
        expect(InvViewModel().totalPnLPercent, 0.0);
      },
    );

    test(
      'allTransactions agrega transacciones de todos los items ordenadas por fecha descendente',
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

  group('InvViewModel: preferencias', () {
    test('toggleTheme invierte isDarkMode y lo persiste', () async {
      final vm = InvViewModel();
      final before = vm.isDarkMode;
      vm.toggleTheme();
      expect(vm.isDarkMode, !before);

      final vm2 = InvViewModel();
      await vm2.initSettings();
      expect(vm2.isDarkMode, !before);
    });

    test('setLanguage actualiza currentLocale y lo persiste', () async {
      final vm = InvViewModel();
      vm.setLanguage('gl');
      expect(vm.currentLocale, 'gl');

      final vm2 = InvViewModel();
      await vm2.initSettings();
      expect(vm2.currentLocale, 'gl');
    });

    test(
      'initSettings carga valores del sistema cuando no hay preferencias guardadas',
      () async {
        final vm = InvViewModel();
        await vm.initSettings();
        // En el entorno de test, el brillo de la plataforma es light → isDarkMode = false
        expect(vm.isDarkMode, isFalse);
        // El locale debe ser uno de los idiomas soportados o el fallback 'es'
        expect(['es', 'gl', 'en'].contains(vm.currentLocale), isTrue);
      },
    );
  });

  group('InvViewModel: sesión', () {
    test('logout limpia currentUser, itemList y categories', () async {
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
      'hasUserSession devuelve false cuando no hay sesión guardada',
      () async {
        expect(await InvViewModel().loadUserSession(), isFalse);
      },
    );

    test(
      'hasUserSession devuelve true cuando hay userId en SharedPreferences',
      () async {
        SharedPreferences.setMockInitialValues({'current_user_id': '42'});
        expect(await InvViewModel().loadUserSession(), isTrue);
      },
    );

    test(
      'checkLocalSession devuelve true y establece currentUser cuando hay usuario en SQLite',
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
      'checkLocalSession devuelve false cuando no hay usuario en SQLite',
      () async {
        expect(await InvViewModel().checkLocalSession(), isFalse);
      },
    );
  });

  group('InvViewModel: autenticación', () {
    test(
      'login devuelve true, establece currentUser y marca isOnline',
      () async {
        final vm = InvViewModel();
        final success = await vm.login('alice', '1234');

        expect(success, isTrue);
        expect(vm.currentUser?.username, 'alice');
        expect(vm.currentUser?.token, 'tok');
        expect(vm.isOnline, isTrue);
      },
    );

    test('register devuelve true cuando el servidor responde 201', () async {
      expect(
        await InvViewModel().register('nuevo', '1234', 'nuevo@test.com'),
        isTrue,
      );
    });
  });

  group('InvViewModel: carga de datos', () {
    test(
      'fetchCategories rellena la lista cuando hay usuario activo',
      () async {
        final vm = InvViewModel();
        await vm.login('alice', '1234');

        await vm.fetchCategories();

        expect(vm.categories, isNotEmpty);
        expect(vm.categories.first.name, 'Crypto');
      },
    );

    test('fetchCategories no hace nada si no hay usuario activo', () async {
      final vm = InvViewModel();

      await vm.fetchCategories();

      expect(vm.categories, isEmpty);
    });
  });
}
