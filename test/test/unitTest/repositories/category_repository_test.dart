import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:investment_tracking/database/database_helper.dart';
import 'package:investment_tracking/repositories/category_repository.dart';
import '../../helpers/db_test_helper.dart';
import '../../helpers/http_mock.dart';

void main() {
  setUpAll(setUpDatabase);
  tearDownAll(tearDownDatabase);
  setUp(clearAllTables);
  tearDown(clearAllTables);

  group('CategoryRepository', () {
    setUp(() {
      HttpOverrides.global = MockHttpOverrides((url) async {
        if (url.path.contains('/categories')) {
          return MockHttpResponse(json.encode([
            {'id': 1, 'name': 'Stocks'},
            {'id': 2, 'name': 'Crypto'},
          ]));
        }
        return MockHttpResponse('[]');
      });
    });

    test('getAllCategories devuelve lista del servidor y la persiste', () async {
      final categories =
          await CategoryRepository().getAllCategories('token_abc');

      expect(categories.length, 2);
      expect(categories.any((c) => c.name == 'Stocks'), isTrue);
    });

    test('getAllCategories devuelve lista desde SQLite cuando el servidor falla',
        () async {
      final db = await DatabaseHelper.instance.database;
      await db.insert('categories', {'name': 'Stocks'});
      await db.insert('categories', {'name': 'Crypto'});

      HttpOverrides.global = MockHttpOverrides((_) async {
        throw const SocketException('sin red');
      });

      final categories =
          await CategoryRepository().getAllCategories('token_abc');

      expect(categories, isNotEmpty);
    });
  });
}
