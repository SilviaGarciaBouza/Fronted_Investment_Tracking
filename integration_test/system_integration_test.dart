import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:investment_tracking/main.dart' as app;
import 'package:shared_preferences/shared_preferences.dart';
import 'helpers/widget_tester_x.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'System E2E: login → portfolio loaded → add transaction → delete transaction → verify removal',
    (WidgetTester tester) async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('app_lang', 'es');

      app.main();
      await tester.pumpAndSettle();

      if (tester.any(find.byType(TextField))) {
        await tester.enterText(find.byType(TextField).at(0), 's@s.com');
        await tester.enterText(find.byType(TextField).at(1), '1234');
        await tester.tap(find.byType(ElevatedButton).first);
        await tester.pumpAndSettle();
      }

      await Future.delayed(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      expect(find.text('MI CARTERA'), findsOneWidget);

      await tester.addTransaction();

      await tester.tap(find.byIcon(Icons.delete_outline).first);
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);

      await tester.tap(find.text('BORRAR'));
      await tester.pump();
      await tester.pumpUntilGone(find.byType(AlertDialog));

      await tester.pumpUntilGone(
        find.byType(CircularProgressIndicator),
        timeout: const Duration(seconds: 15),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.textContaining('borrada'), findsOneWidget);

      expect(find.text('MI CARTERA'), findsOneWidget);
    },
  );
}
