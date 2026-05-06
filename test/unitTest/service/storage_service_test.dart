import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:investment_tracking/service/storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('StorageService', () {
    test('write and read round-trip', () async {
      final storage = StorageService();

      await storage.write('myKey', 'myValue');

      expect(await storage.read('myKey'), 'myValue');
    });

    test('delete makes read return null', () async {
      final storage = StorageService();
      await storage.write('myKey', 'myValue');

      await storage.delete('myKey');

      expect(await storage.read('myKey'), isNull);
    });

    test('read of non-existent key returns null', () async {
      expect(await StorageService().read('nonExistent'), isNull);
    });
  });
}
