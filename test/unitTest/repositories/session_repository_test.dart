import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:investment_tracking/repositories/session_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('SessionRepository', () {
    test('saveUserId and getUserId round-trip', () async {
      final repo = SessionRepository();

      await repo.saveUserId(42);

      expect(await repo.getUserId(), 42);
    });

    test('clearUserId makes getUserId return null', () async {
      final repo = SessionRepository();
      await repo.saveUserId(42);

      await repo.clearUserId();

      expect(await repo.getUserId(), isNull);
    });

    test('getUserId returns null when no userId is stored', () async {
      expect(await SessionRepository().getUserId(), isNull);
    });
  });
}
