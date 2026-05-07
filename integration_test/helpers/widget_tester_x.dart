import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

extension WidgetTesterX on WidgetTester {
  Future<void> pumpUntilGone(
    Finder finder, {
    Duration step = const Duration(milliseconds: 200),
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final deadline = DateTime.now().add(timeout);
    while (any(finder) && DateTime.now().isBefore(deadline)) {
      await pump(step);
    }
  }

  Future<void> addTransaction() async {
    await tap(find.byType(FloatingActionButton));
    await pumpAndSettle();

    await Future.delayed(const Duration(seconds: 3));
    await pumpAndSettle();

    await tap(find.byType(DropdownButtonFormField<int>));
    await pumpAndSettle();
    await tap(find.byType(DropdownMenuItem<int>).first);
    await pumpAndSettle();

    await tap(find.byType(DropdownButtonFormField<String>));
    await pumpAndSettle();
    await tap(find.byType(DropdownMenuItem<String>).first);
    await pumpAndSettle();

    await enterText(find.byType(TextField).at(0), '1');
    await enterText(find.byType(TextField).at(1), '1');
    await pumpAndSettle();

    await tap(find.textContaining('CONFIRMAR'));
    await pumpAndSettle();

    await Future.delayed(const Duration(seconds: 3));
    await pumpAndSettle();
  }
}
