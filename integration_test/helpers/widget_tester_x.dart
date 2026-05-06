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
}
