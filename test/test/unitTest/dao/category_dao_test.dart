import 'package:flutter_test/flutter_test.dart';
import 'package:investment_tracking/dao/caegory_dao.dart';
import 'package:investment_tracking/database/database_helper.dart';
import '../../helpers/db_test_helper.dart';

void main() {
  setUpAll(setUpDatabase);
  tearDownAll(tearDownDatabase);
  setUp(clearAllTables);
  tearDown(clearAllTables);

  group('CategoryDao', () {
    test('insert and get category', () async {
      final db = await DatabaseHelper.instance.database;
      await db.insert('categories', {'name': 'TestCat'});

      final categories = await CategoryDao().getCategories();

      expect(categories.any((c) => c.name == 'TestCat'), isTrue);
    });
  });
}
