import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:investment_tracking/main.dart' as app;

// E2E system test — zero mocking.
// Requires a real device/simulator and backend running at localhost:8080.
// The test user ('silvia' / '1234') must have at least one transaction.
//
// Run with:
//   flutter drive --target=integration_test/system_integration_test.dart
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

      // Record the number of deletable transactions before deletion
      final deletesBefore =
          tester.widgetList(find.byIcon(Icons.delete_outline)).length;
      expect(
        deletesBefore,
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
      await tester.pumpAndSettle();

      // Wait for DELETE request to complete and list to refresh
      await Future.delayed(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      // Verify the transaction was removed from the UI
      final deletesAfter =
          tester.widgetList(find.byIcon(Icons.delete_outline)).length;
      expect(deletesAfter, lessThan(deletesBefore));

      // Verify we are still on the portfolio screen (no crash, no navigation)
      expect(find.text('MI CARTERA'), findsOneWidget);
    },
  );
}
