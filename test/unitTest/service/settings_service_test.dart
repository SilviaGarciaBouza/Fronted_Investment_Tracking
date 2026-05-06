import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:investment_tracking/service/SettingsService.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('SettingsService', () {
    test('persists and retrieves the language', () async {
      final settings = SettingsService();

      await settings.saveLanguage('gl');

      expect(await settings.getLanguage(), 'gl');
    });

    test('persists and retrieves the theme (dark/light)', () async {
      final settings = SettingsService();

      await settings.saveTheme(true);

      expect(await settings.getTheme(), true);
    });

    test('returns null when no values are stored', () async {
      final settings = SettingsService();

      expect(await settings.getLanguage(), isNull);
      expect(await settings.getTheme(), isNull);
    });
  });
}
