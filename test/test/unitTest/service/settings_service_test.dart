import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:investment_tracking/service/SettingsService.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('SettingsService', () {
    test('persiste y recupera el idioma', () async {
      final settings = SettingsService();

      await settings.saveLanguage('gl');

      expect(await settings.getLanguage(), 'gl');
    });

    test('persiste y recupera el tema (oscuro/claro)', () async {
      final settings = SettingsService();

      await settings.saveTheme(true);

      expect(await settings.getTheme(), true);
    });

    test('devuelve null si no hay valores guardados', () async {
      final settings = SettingsService();

      expect(await settings.getLanguage(), isNull);
      expect(await settings.getTheme(), isNull);
    });
  });
}
