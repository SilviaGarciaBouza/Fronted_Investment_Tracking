import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:investment_tracking/dao/item_dao.dart';
import 'package:investment_tracking/database/database_helper.dart';
import 'package:investment_tracking/models/item.dart';
import 'package:investment_tracking/models/user.dart';
import 'package:investment_tracking/repositories/item_repository.dart';
import 'package:investment_tracking/viewmodels/InvViewModel.dart';
import '../helpers/db_test_helper.dart';
import '../helpers/http_mock.dart';

Map<String, dynamic> _btcItemJson() => {
      'id': 10,
      'name': 'BTCUSDT',
      'category': {'id': 1, 'name': 'Crypto'},
      'currentPrice': 50000.0,
      'transactions': [
        {
          'id': 5,
          'stocks': 2.0,
          'purchasePrice': 25000.0,
          'invEur': 50000.0,
          'purchaseDate': '2024-01-01T00:00:00.000',
        }
      ],
    };

Future<void> _seedFkDeps() async {
  final db = await DatabaseHelper.instance.database;
  await db.insert('users', {
    'id': 1,
    'username': 'alice',
    'email': 'a@b.com',
    'token': 'tok',
  });
  await db.insert('categories', {'id': 1, 'name': 'Crypto'});
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await setUpDatabase();
  });
  tearDownAll(tearDownDatabase);

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await clearAllTables();
  });
  tearDown(clearAllTables);

  // ─── Level 1: DAO + SQLite ───────────────────────────────────────────────
  // No HTTP, no ViewModel. SQLite is the system under test.
  group('Level 1 — DAO + SQLite', () {
    test('ItemDao persists and retrieves an item with its transaction', () async {
      await _seedFkDeps();

      final items = [Item.fromJson(_btcItemJson())];
      await ItemDao().saveItems(items, 1);

      final recovered = await ItemDao().getItems(1);
      expect(recovered.length, 1);
      expect(recovered.first.name, 'BTCUSDT');
      expect(recovered.first.serverId, 10);
      expect(recovered.first.transactions.length, 1);
      expect(recovered.first.transactions.first.stocks, 2.0);
    });
  });

  // ─── Level 2: Repository + DAO ───────────────────────────────────────────
  // HTTP mocked. Verifies that the repository writes server data into SQLite.
  group('Level 2 — Repository + DAO', () {
    setUp(() {
      HttpOverrides.global = MockHttpOverrides((url) async {
        if (url.path.contains('/items/user/1')) {
          return MockHttpResponse(json.encode([_btcItemJson()]));
        }
        return MockHttpResponse('[]');
      });
    });

    test('fetchUserItems fetches server data and persists it to SQLite', () async {
      await _seedFkDeps();

      final items = await ItemRepository().fetchUserItems(1, 'tok');

      expect(items.length, 1);
      expect(items.first.name, 'BTCUSDT');
      expect(items.first.serverId, 10);
      expect(items.first.transactions.length, 1);

      // DAO confirms SQLite persistence independently of repository return value
      final local = await ItemDao().getItems(1);
      expect(local.length, 1);
      expect(local.first.serverId, 10);
    });
  });

  // ─── Level 3: ViewModel + Repository + DAO (offline) ────────────────────
  // HTTP throws SocketException → Repository falls back → DAO reads SQLite.
  group('Level 3 — ViewModel + Repository + DAO (no network, SQLite fallback)', () {
    setUp(() {
      HttpOverrides.global = MockHttpOverrides((_) async {
        throw const SocketException('sin red');
      });
    });

    test('fetchItems serves data from SQLite when server is unreachable', () async {
      await _seedFkDeps();

      // Pre-seed item to simulate previously synced local data
      await ItemDao().saveItems([Item.fromJson(_btcItemJson())], 1);

      // Set currentUser directly (public field) — isolates fetchItems from login flow
      final vm = InvViewModel();
      vm.currentUser = User(id: 1, username: 'alice', email: 'a@b.com', token: 'tok');
      await vm.fetchItems();

      expect(vm.itemList.length, 1);
      expect(vm.itemList.first.name, 'BTCUSDT');
      expect(vm.itemList.first.transactions.length, 1);
    });
  });
}
