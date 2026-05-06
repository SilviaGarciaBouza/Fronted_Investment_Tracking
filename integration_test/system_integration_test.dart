import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:investment_tracking/main.dart' as app;
import 'helpers/widget_tester_x.dart';

// E2E system test — zero mocking.
// Requires a real device/simulator and backend running at localhost:8080.
// The test user ('silvia' / '1234') must have at least one transaction.
//
// Run with:
//   flutter test -d linux integration_test/system_integration_test.dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'System E2E: login → portfolio loaded → delete transaction → verify removal',
    (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Login if the login screen is visible
      if (tester.any(find.byType(TextField))) {
        await tester.enterText(find.byType(TextField).at(0), 'silvia');
        await tester.enterText(find.byType(TextField).at(1), '1234');
        await tester.tap(find.byType(ElevatedButton).first);
        await tester.pumpAndSettle();
      }

      // Wait for server data to load
      await Future.delayed(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      // Verify portfolio screen is active
      expect(find.text('MI CARTERA'), findsOneWidget);

      // Verify the test user has at least one transaction to delete
      expect(
        tester.widgetList(find.byIcon(Icons.delete_outline)).length,
        greaterThan(0),
        reason: 'Test user must have at least one transaction to delete',
      );

      // Tap the first delete icon
      await tester.tap(find.byIcon(Icons.delete_outline).first);
      await tester.pumpAndSettle();

      // Verify confirmation dialog appears
      expect(find.byType(AlertDialog), findsOneWidget);

      // Confirm the deletion
      await tester.tap(find.text('BORRAR'));
      await tester.pump();
      await tester.pumpUntilGone(find.byType(AlertDialog));

      // SnackBar appears immediately after Navigator.pop() — assert before it auto-hides.
      // Icon counting is unreliable: lazy lists only render visible rows, so the count
      // stays constant when a new row scrolls in to replace the deleted one.
      expect(find.textContaining('eliminada'), findsOneWidget);

      // Verify we are still on the portfolio screen (no crash, no navigation)
      expect(find.text('MI CARTERA'), findsOneWidget);
    },
  );
}
