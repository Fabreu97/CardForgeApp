import 'dart:async';

import 'package:cardforge/features/control/control_models.dart';
import 'package:cardforge/features/control/machine_control_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_helpers.dart';

const _linked = <String, Object>{
  'machine_id': 'B8:27:EB:00:A1:B2',
  'machine_name': 'CardForge-A1B2',
};

const _startKey = ValueKey('start-button');
const _stopKey = ValueKey('stop-button');

/// Fails the status or the commands, to test the error states.
class _FailingService implements MachineControlService {
  _FailingService({this.statusFailure, this.commandFailure});

  final MachineControlFailure? statusFailure;
  final MachineControlFailure? commandFailure;

  @override
  Future<MachineRunState> status(String machineId) async {
    if (statusFailure != null) throw MachineControlException(statusFailure!);
    return MachineRunState.idle;
  }

  @override
  Future<MachineRunState> start(String machineId) async {
    if (commandFailure != null) throw MachineControlException(commandFailure!);
    return MachineRunState.running;
  }

  @override
  Future<MachineRunState> stop(String machineId) async =>
      MachineRunState.stopped;
}

/// Start answers only when the test completes it.
class _SlowStartService implements MachineControlService {
  final Completer<MachineRunState> startAnswer = Completer();

  @override
  Future<MachineRunState> status(String machineId) async => MachineRunState.idle;

  @override
  Future<MachineRunState> start(String machineId) => startAnswer.future;

  @override
  Future<MachineRunState> stop(String machineId) async =>
      MachineRunState.stopped;
}

void main() {
  setUpAll(configureTestEnvironment);
  setUp(() => resetAuthState(stored: {'access_token': 'abc'}));

  Future<void> openControl(
    WidgetTester tester, {
    MachineControlService? service,
    Map<String, Object> preferences = _linked,
  }) async {
    await pumpApp(
      tester,
      initialLocation: '/control',
      machineControl: service,
      preferences: preferences,
    );
    await tester.pumpAndSettle();
  }

  bool enabled(WidgetTester tester, Key key) {
    final widget = tester.widget(find.byKey(key));
    return widget is FilledButton
        ? widget.onPressed != null
        : (widget as OutlinedButton).onPressed != null;
  }

  testWidgets('shows two big buttons: Start/Resume and Stop', (tester) async {
    await openControl(tester);

    expect(find.text('Start/Resume'), findsOneWidget);
    expect(find.text('Stop'), findsOneWidget);
    expect(tester.getSize(find.byKey(_startKey)).height, greaterThanOrEqualTo(96));
    expect(tester.getSize(find.byKey(_stopKey)).height, greaterThanOrEqualTo(96));
  });

  testWidgets('a ready machine can be started but not stopped',
      (tester) async {
    await openControl(tester);

    expect(find.text('CardForge-A1B2'), findsOneWidget);
    expect(find.text('Ready'), findsOneWidget);
    expect(find.text('Ready to start sorting.'), findsOneWidget);
    expect(enabled(tester, _startKey), isTrue);
    expect(enabled(tester, _stopKey), isFalse);
  });

  testWidgets('Start, Stop and Resume change the state and the buttons',
      (tester) async {
    await openControl(tester);

    await tester.tap(find.byKey(_startKey));
    await tester.pumpAndSettle();
    expect(find.text('Running'), findsOneWidget);
    expect(find.text('Sorting cards…'), findsOneWidget);
    expect(enabled(tester, _startKey), isFalse);
    expect(enabled(tester, _stopKey), isTrue);

    await tester.tap(find.byKey(_stopKey));
    await tester.pumpAndSettle();
    expect(find.text('Stopped'), findsOneWidget);
    expect(find.text('Sorting is stopped. Tap Start/Resume to continue.'),
        findsOneWidget);
    expect(enabled(tester, _startKey), isTrue);
    expect(enabled(tester, _stopKey), isFalse);

    await tester.tap(find.byKey(_startKey));
    await tester.pumpAndSettle();
    expect(find.text('Running'), findsOneWidget);
  });

  testWidgets('while a command is being sent both buttons are disabled and the '
      'pressed one shows a spinner', (tester) async {
    final service = _SlowStartService();
    await openControl(tester, service: service);

    await tester.tap(find.byKey(_startKey));
    await tester.pump();

    expect(enabled(tester, _startKey), isFalse);
    expect(enabled(tester, _stopKey), isFalse);
    expect(
      find.descendant(
          of: find.byKey(_startKey), matching: find.byType(CircularProgressIndicator)),
      findsOneWidget,
    );

    service.startAnswer.complete(MachineRunState.running);
    await tester.pumpAndSettle();

    expect(find.text('Running'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('the state is kept when the screen is left and opened again',
      (tester) async {
    await pumpApp(tester, initialLocation: '/home', preferences: _linked);

    Finder inDrawer(String text) =>
        find.descendant(of: find.byType(Drawer), matching: find.text(text));

    await tester.tap(find.byType(DrawerButton));
    await tester.pumpAndSettle();
    await tester.tap(inDrawer('Machine control'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(_startKey));
    await tester.pumpAndSettle();
    expect(find.text('Running'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DrawerButton));
    await tester.pumpAndSettle();
    await tester.tap(inDrawer('Machine control'));
    await tester.pumpAndSettle();

    expect(find.text('Running'), findsOneWidget);
    expect(enabled(tester, _stopKey), isTrue);
  });

  testWidgets('without a linked machine, the buttons are off and linking is '
      'one tap away', (tester) async {
    await openControl(tester, preferences: const {});

    expect(find.text('No machine linked'), findsOneWidget);
    expect(enabled(tester, _startKey), isFalse);
    expect(enabled(tester, _stopKey), isFalse);

    await tester.tap(find.widgetWithText(FilledButton, 'Link machine'));
    await tester.pumpAndSettle();

    expect(find.text('Select your machine'), findsOneWidget);
  });

  testWidgets('an offline machine shows the reason and can be tried again',
      (tester) async {
    await openControl(
      tester,
      service: _FailingService(commandFailure: MachineControlFailure.machineOffline),
    );

    await tester.tap(find.byKey(_startKey));
    await tester.pumpAndSettle();

    expect(
      find.text('The machine is offline. Check that it is on and connected to Wi-Fi.'),
      findsOneWidget,
    );
    expect(find.text('Ready'), findsOneWidget); // state did not change
    expect(enabled(tester, _startKey), isTrue);
  });

  testWidgets('an expired session offers to sign in again', (tester) async {
    await openControl(
      tester,
      service: _FailingService(statusFailure: MachineControlFailure.unauthorized),
    );

    expect(find.text('Could not get the machine status'), findsOneWidget);
    expect(find.text('Your session expired. Please sign in again.'),
        findsOneWidget);
    expect(enabled(tester, _startKey), isFalse);

    await tester.tap(find.widgetWithText(FilledButton, 'Sign in again'));
    await tester.pumpAndSettle();

    expect(find.text('Sign in to manage your sorter'), findsOneWidget);
  });

  testWidgets('works in Portuguese', (tester) async {
    await openControl(tester, preferences: {..._linked, 'language_code': 'pt'});

    expect(find.text('Iniciar/Continuar'), findsOneWidget);
    expect(find.text('Parar'), findsOneWidget);
    expect(find.text('Pronta'), findsOneWidget);

    await tester.tap(find.byKey(_startKey));
    await tester.pumpAndSettle();

    expect(find.text('Em execução'), findsOneWidget);
  });
}
