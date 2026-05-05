import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:investment_tracking/repositories/session_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('SessionRepository', () {
    test('saveUserId y getUserId round-trip', () async {
      final repo = SessionRepository();

      await repo.saveUserId(42);

      expect(await repo.getUserId(), 42);
    });

    test('clearUserId hace que getUserId devuelva null', () async {
      final repo = SessionRepository();
      await repo.saveUserId(42);

      await repo.clearUserId();

      expect(await repo.getUserId(), isNull);
    });

    test('getUserId devuelve null si no hay userId guardado', () async {
      expect(await SessionRepository().getUserId(), isNull);
    });
  });
}
