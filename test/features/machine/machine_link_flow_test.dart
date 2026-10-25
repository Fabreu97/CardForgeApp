import 'dart:async';

import 'package:cardforge/features/machine/machine_link_flow.dart';
import 'package:cardforge/features/machine/machine_link_service.dart';
import 'package:cardforge/features/machine/machine_models.dart';
import 'package:cardforge/features/machine/mock_machine_link_service.dart';
import 'package:flutter_test/flutter_test.dart';

const _machine = DiscoveredMachine(
  id: 'B8:27:EB:00:A1:B2',
  name: 'CardForge-A1B2',
  signalDbm: -48,
);

/// A machine that accepts the password but never confirms the link.
class _HangingService implements MachineLinkService {
  @override
  Stream<List<DiscoveredMachine>> scan() => Stream.value(const [_machine]);

  @override
  Future<void> authenticate({
    required String machineId,
    required String password,
  }) async {}

  @override
  Stream<LinkStep> link({
    required DiscoveredMachine machine,
    WifiCredentials? wifi,
  }) =>
      StreamController<LinkStep>().stream; // never emits
}

/// Waits (in real time) until [condition] is true.
Future<void> settle(bool Function() condition) async {
  for (var i = 0; i < 400 && !condition(); i++) {
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
  expect(condition(), isTrue, reason: 'condition was not met in time');
}

void main() {
  LinkedMachine? linked;
  bool? lastWifiSent;

  MachineLinkFlow makeFlow(
    MachineLinkService service, {
    Duration timeout = const Duration(seconds: 5),
  }) {
    final flow = MachineLinkFlow(
      service,
      linkTimeout: timeout,
      onLinked: (machine, {required wifiSent}) {
        linked = machine;
        lastWifiSent = wifiSent;
      },
    );
    addTearDown(flow.dispose);
    return flow;
  }

  MockMachineLinkService fastMock() =>
      MockMachineLinkService(stepDelay: Duration.zero);

  /// Runs the flow up to the "Send Wi-Fi details?" question.
  Future<MachineLinkFlow> flowAtWifiQuestion() async {
    final flow = makeFlow(fastMock());
    flow.startScan();
    await settle(() => flow.machines.isNotEmpty);
    flow.select(flow.machines.first);
    await flow.submitPassword('1234');
    expect(flow.phase, LinkPhase.wifiQuestion);
    return flow;
  }

  setUp(() {
    linked = null;
    lastWifiSent = null;
  });

  test('the scan lists the machines found and then stops scanning', () async {
    final flow = makeFlow(fastMock());

    flow.startScan();
    expect(flow.scanning, isTrue);

    await settle(() => !flow.scanning);
    expect(flow.machines.map((m) => m.name),
        ['CardForge-A1B2', 'CardForge-9F3C']);
    expect(flow.scanFailure, isNull);
  });

  test('selecting a machine moves to the password step', () async {
    final flow = makeFlow(fastMock());
    flow.startScan();
    await settle(() => flow.machines.isNotEmpty);

    flow.select(flow.machines.first);

    expect(flow.phase, LinkPhase.password);
    expect(flow.selected?.name, 'CardForge-A1B2');
    expect(flow.scanning, isFalse);
  });

  test('a wrong password keeps the step and reports the failure', () async {
    final flow = makeFlow(fastMock());
    flow.startScan();
    await settle(() => flow.machines.isNotEmpty);
    flow.select(flow.machines.first);

    await flow.submitPassword(MockMachineLinkService.rejectedPassword);

    expect(flow.phase, LinkPhase.password);
    expect(flow.passwordFailure, MachineLinkFailure.wrongPassword);
    expect(flow.checkingPassword, isFalse);

    flow.clearPasswordFailure();
    expect(flow.passwordFailure, isNull);

    await flow.submitPassword('1234');
    expect(flow.phase, LinkPhase.wifiQuestion);
  });

  test('going back from the password step returns to the list', () async {
    final flow = makeFlow(fastMock());
    flow.startScan();
    await settle(() => flow.machines.isNotEmpty);
    flow.select(flow.machines.first);

    flow.backToList();

    expect(flow.phase, LinkPhase.deviceList);
    expect(flow.selected, isNull);
  });

  test('skipping Wi-Fi links the machine right away', () async {
    final flow = await flowAtWifiQuestion();

    flow.answerWifiQuestion(send: false);
    expect(flow.phase, LinkPhase.linking);
    await settle(() => flow.phase == LinkPhase.success);

    expect(flow.sentWifi, isFalse);
    expect(linked?.name, 'CardForge-A1B2');
    expect(lastWifiSent, isFalse);
  });

  test('sending Wi-Fi goes through every step and links the machine',
      () async {
    final flow = await flowAtWifiQuestion();
    final seen = <LinkStep>[];
    flow.addListener(() {
      final step = flow.step;
      if (step != null && (seen.isEmpty || seen.last != step)) seen.add(step);
    });

    flow.answerWifiQuestion(send: true);
    expect(flow.phase, LinkPhase.wifiForm);

    flow.submitWifi(const WifiCredentials(ssid: 'HomeWiFi', password: 'secret123'));
    await settle(() => flow.phase == LinkPhase.success);

    expect(seen, [
      LinkStep.sendingWifi,
      LinkStep.waitingForWifi,
      LinkStep.linkingAccount,
      LinkStep.done,
    ]);
    expect(flow.sentWifi, isTrue);
    expect(lastWifiSent, isTrue);
    expect(linked?.id, 'B8:27:EB:00:A1:B2');
  });

  test('the Wi-Fi form can go back to the question', () async {
    final flow = await flowAtWifiQuestion();
    flow.answerWifiQuestion(send: true);

    flow.backToWifiQuestion();

    expect(flow.phase, LinkPhase.wifiQuestion);
  });

  test('a network the machine cannot join ends in a failure, and retry restarts',
      () async {
    final flow = await flowAtWifiQuestion();
    flow.answerWifiQuestion(send: true);

    flow.submitWifi(const WifiCredentials(
      ssid: MockMachineLinkService.failingNetwork,
      password: 'x',
    ));
    await settle(() => flow.phase == LinkPhase.failure);

    expect(flow.failure, MachineLinkFailure.wifiFailed);
    expect(linked, isNull);

    flow.startScan();
    expect(flow.phase, LinkPhase.deviceList);
    expect(flow.failure, isNull);
    await settle(() => flow.machines.isNotEmpty);
  });

  test('fails with a timeout when the machine never confirms', () async {
    final flow = makeFlow(
      _HangingService(),
      timeout: const Duration(milliseconds: 50),
    );
    flow.startScan();
    await settle(() => flow.machines.isNotEmpty);
    flow.select(flow.machines.first);
    await flow.submitPassword('1234');

    flow.answerWifiQuestion(send: false);
    expect(flow.isBusy, isTrue);

    await settle(() => flow.phase == LinkPhase.failure);
    expect(flow.failure, MachineLinkFailure.timeout);
    expect(flow.isBusy, isFalse);
  });

  test('without the real Bluetooth transport the scan reports notImplemented',
      () async {
    final flow = makeFlow(const UnavailableMachineLinkService());

    flow.startScan();
    await settle(() => !flow.scanning);

    expect(flow.scanFailure, MachineLinkFailure.notImplemented);
    expect(flow.machines, isEmpty);
  });

  test('signal level goes from weak to strong', () {
    DiscoveredMachine at(int dbm) =>
        DiscoveredMachine(id: 'x', name: 'x', signalDbm: dbm);

    expect(at(-48).signalLevel, 3);
    expect(at(-70).signalLevel, 2);
    expect(at(-90).signalLevel, 1);
  });
}
