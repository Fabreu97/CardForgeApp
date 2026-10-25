import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_helpers.dart';

void main() {
  setUpAll(configureTestEnvironment);
  setUp(() => resetAuthState(stored: {'access_token': 'abc'}));

  const symbols = ValueKey('mana-symbols');

  testWidgets('Splash shows the symbols', (tester) async {
    await pumpApp(tester, initialLocation: '/splash');

    expect(find.byKey(symbols), findsOneWidget);

    // Let the splash finish so no timer is left running.
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
  });

  for (final route in [
    '/login',
    '/home',
    '/link-machine',
    '/alerts',
    '/settings',
    '/cards',
    '/control',
  ]) {
    testWidgets('$route shows the symbols above its content', (tester) async {
      await pumpApp(tester, initialLocation: route);
      await tester.pumpAndSettle();

      expect(find.byKey(symbols), findsOneWidget);
      // Nothing is drawn on top of the symbols' area except the app bar.
      final symbolsRect = tester.getRect(find.byKey(symbols));
      expect(symbolsRect.top, greaterThanOrEqualTo(0));
      expect(symbolsRect.bottom, lessThan(300));
    });
  }
}
