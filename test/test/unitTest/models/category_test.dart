import 'package:flutter_test/flutter_test.dart';
import 'package:investment_tracking/models/category.dart';

void main() {
  group('Category: serialización y mapeo', () {
    test('fromJson convierte ID de String a int', () {
      final json = {'id': '5', 'name': 'Divisa'};

      final cat = Category.fromJson(json);

      expect(cat.id, 5);
      expect(cat.id, isA<int>());
    });
  });
}
