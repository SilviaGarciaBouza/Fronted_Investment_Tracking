import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:investment_tracking/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Flujo E2E: Login y Navegación a Detalle de Activo', (
    WidgetTester tester,
  ) async {
    app.main();
    await tester.pumpAndSettle();

    // Me logueo
    final Finder elevatedButtons = find.byType(ElevatedButton);
    if (tester.any(elevatedButtons)) {
      final Finder textFields = find.byType(TextField);
      await tester.enterText(textFields.at(0), 'silvia');
      await tester.enterText(textFields.at(1), '1234');
      await tester.tap(elevatedButtons.first);
      await tester.pumpAndSettle();
    }

    // Espero a que carguen los datos
    await Future.delayed(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    // selecciono el activo BTCUSDT
    final Finder itemBtc = find.text('BTCUSDT');
    expect(
      itemBtc,
      findsOneWidget,
      reason: 'No se encontró BTCUSDT en la lista',
    );

    await tester.tap(itemBtc);
    await tester.pumpAndSettle();
    await Future.delayed(const Duration(seconds: 1));

    // verifico que estoy en la pantalla detalle
    expect(find.textContaining('Media'), findsOneWidget);

    // Le doy a vo.lver a atrás
    await tester.pageBack();
    await tester.pumpAndSettle();

    // Vuelvo a home, verifico que hay escrito mi cartera
    expect(find.text('MI CARTERA'), findsOneWidget);

    print('TEST DE SISTEMA COMPLETADO EN ESPAÑOL');
  });
}
