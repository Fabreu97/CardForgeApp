import 'package:cardforge/core/app_scope.dart';
import 'package:cardforge/features/alerts/machine_alert.dart';
import 'package:cardforge/features/machine/machine_link_service.dart';
import 'package:cardforge/features/machine/machine_models.dart';
import 'package:cardforge/features/machine/mock_machine_link_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_helpers.dart';

/// A scan that finishes without finding anything.
class _EmptyService extends UnavailableMachineLinkService {
  const _EmptyService();

  @override
  Stream<List<DiscoveredMachine>> scan() =>
      Stream<List<DiscoveredMachine>>.value(const []);
}

void main() {
  setUpAll(configureTestEnvironment);

  /// Opens Home and taps "Link machine".
  Future<AppDependencies> openLinkScreen(
    WidgetTester tester, {
    MachineLinkService? linkService,
    Map<String, Object> preferences = const {},
  }) async {
    final deps = await pumpApp(
      tester,
      initialLocation: '/home',
      linkService: linkService,
      preferences: preferences,
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Link machine'));
    await tester.pumpAndSettle();
    return deps;
  }

  Future<void> pickMachineAndEnterPassword(
    WidgetTester tester,
    String password,
  ) async {
    await tester.tap(find.text('CardForge-A1B2'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), password);
    await tester.tap(find.widgetWithText(FilledButton, 'Verify password'));
    await tester.pumpAndSettle();
  }

  testWidgets('lists the machines found by the scan', (tester) async {
    await openLinkScreen(tester);

    expect(find.text('Select your machine'), findsOneWidget);
    expect(find.text('CardForge-A1B2'), findsOneWidget);
    expect(find.text('CardForge-9F3C'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'Scan again'), findsOneWidget);
  });

  testWidgets('links a machine and sends the Wi-Fi details', (tester) async {
    final deps = await openLinkScreen(tester);

    await pickMachineAndEnterPassword(tester, '1234');
    expect(find.text('Send Wi-Fi details?'), findsOneWidget);

    await tester.tap(find.text('Yes, send Wi-Fi'));
    await tester.pumpAndSettle();
    expect(find.text('Wi-Fi details'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).at(0), 'HomeWiFi');
    await tester.enterText(find.byType(TextFormField).at(1), 'secret123');
    await tester.tap(find.widgetWithText(FilledButton, 'Send and link'));
    await tester.pumpAndSettle();

    expect(find.text('Machine linked!'), findsOneWidget);
    expect(deps.machineStore.machine?.name, 'CardForge-A1B2');
    // Newest first: Wi-Fi was announced after the link itself.
    expect(deps.alerts.alerts.map((a) => a.type),
        [AlertType.wifiConnected, AlertType.machineLinked]);

    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();

    expect(find.text('CardForge-A1B2'), findsOneWidget);
    expect(find.text('Linked to your account'), findsOneWidget);
    expect(find.descendant(of: find.byType(Badge), matching: find.text('2')),
        findsOneWidget);
  });

  testWidgets('can skip the Wi-Fi details', (tester) async {
    final deps = await openLinkScreen(tester);

    await pickMachineAndEnterPassword(tester, '1234');
    await tester.tap(find.text('Skip for now'));
    await tester.pumpAndSettle();

    expect(find.text('Machine linked!'), findsOneWidget);
    expect(deps.alerts.alerts.map((a) => a.type), [AlertType.machineLinked]);
  });

  testWidgets('a wrong machine password shows an error and stays on the step',
      (tester) async {
    await openLinkScreen(tester);

    await pickMachineAndEnterPassword(
        tester, MockMachineLinkService.rejectedPassword);

    expect(find.text('Wrong machine password.'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Verify password'), findsOneWidget);
    expect(find.text('Send Wi-Fi details?'), findsNothing);
  });

  testWidgets('asks for the machine password and the network name',
      (tester) async {
    await openLinkScreen(tester);
    await tester.tap(find.text('CardForge-A1B2'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Verify password'));
    await tester.pump();
    expect(find.text('Enter the machine password'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField), '1234');
    await tester.tap(find.widgetWithText(FilledButton, 'Verify password'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Yes, send Wi-Fi'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Send and link'));
    await tester.pump();
    expect(find.text('Enter the network name'), findsOneWidget);
  });

  testWidgets('a failed Wi-Fi connection shows the failure and allows retry',
      (tester) async {
    await openLinkScreen(tester);
    await pickMachineAndEnterPassword(tester, '1234');

    await tester.tap(find.text('Yes, send Wi-Fi'));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byType(TextFormField).at(0), MockMachineLinkService.failingNetwork);
    await tester.tap(find.widgetWithText(FilledButton, 'Send and link'));
    await tester.pumpAndSettle();

    expect(find.text('Could not link the machine'), findsOneWidget);
    expect(
      find.text('The machine could not connect to that Wi-Fi network. '
          'Check the name and password.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(find.text('Select your machine'), findsOneWidget);
  });

  testWidgets('shows a hint when no machine is found', (tester) async {
    await openLinkScreen(tester, linkService: const _EmptyService());

    expect(find.text('No machines found'), findsOneWidget);
    expect(find.textContaining('powered on and nearby'), findsOneWidget);
  });

  testWidgets('explains when real Bluetooth is not available yet',
      (tester) async {
    await openLinkScreen(
      tester,
      linkService: const UnavailableMachineLinkService(),
    );

    expect(find.text('Bluetooth search failed'), findsOneWidget);
    expect(find.text('Bluetooth linking is not available in this build yet.'),
        findsOneWidget);
  });

  testWidgets('works in Portuguese', (tester) async {
    await pumpApp(
      tester,
      initialLocation: '/home',
      preferences: {'language_code': 'pt'},
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Vincular máquina'));
    await tester.pumpAndSettle();

    expect(find.text('Selecione sua máquina'), findsOneWidget);

    await tester.tap(find.text('CardForge-A1B2'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), '1234');
    await tester.tap(find.widgetWithText(FilledButton, 'Verificar senha'));
    await tester.pumpAndSettle();

    expect(find.text('Enviar dados do Wi-Fi?'), findsOneWidget);
  });
}
