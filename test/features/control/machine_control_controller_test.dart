import 'dart:async';

import 'package:cardforge/features/control/control_models.dart';
import 'package:cardforge/features/control/machine_control_controller.dart';
import 'package:cardforge/features/control/machine_control_service.dart';
import 'package:cardforge/features/control/mock_machine_control_service.dart';
import 'package:cardforge/features/machine/machine_models.dart';
import 'package:flutter_test/flutter_test.dart';

const _machine = LinkedMachine(id: 'm1', name: 'CardForge-A1B2');

/// Answers commands only when the test says so, and counts them.
class _ControlledService implements MachineControlService {
  final Completer<MachineRunState> startAnswer = Completer();
  int startCalls = 0;

  @override
  Future<MachineRunState> status(String machineId) async => MachineRunState.idle;

  @override
  Future<MachineRunState> start(String machineId) {
    startCalls++;
    return startAnswer.future;
  }

  @override
  Future<MachineRunState> stop(String machineId) async => MachineRunState.stopped;
}

class _FailingService implements MachineControlService {
  _FailingService(this.failure, {this.statusWorks = true});

  final MachineControlFailure failure;
  final bool statusWorks;

  @override
  Future<MachineRunState> status(String machineId) async {
    if (statusWorks) return MachineRunState.idle;
    throw MachineControlException(failure);
  }

  @override
  Future<MachineRunState> start(String machineId) =>
      Future.error(MachineControlException(failure));

  @override
  Future<MachineRunState> stop(String machineId) =>
      Future.error(MachineControlException(failure));
}

void main() {
  MachineControlController make(
    MachineControlService service, {
    LinkedMachine? machine = _machine,
  }) {
    final controller = MachineControlController(service, machine);
    addTearDown(controller.dispose);
    return controller;
  }

  MockMachineControlService fastMock() =>
      MockMachineControlService(latency: Duration.zero);

  test('without a linked machine nothing can be sent', () async {
    final c = make(fastMock(), machine: null);

    await c.load();
    await c.start();

    expect(c.hasMachine, isFalse);
    expect(c.state, isNull);
    expect(c.canStart, isFalse);
    expect(c.canStop, isFalse);
  });

  test('nothing can be sent until the state is known', () async {
    final c = make(fastMock());

    expect(c.state, isNull);
    expect(c.canStart, isFalse);
    expect(c.canStop, isFalse);

    final loading = c.load();
    expect(c.loading, isTrue);
    expect(c.canStart, isFalse);
    await loading;

    expect(c.state, MachineRunState.idle);
    expect(c.canStart, isTrue);
    expect(c.canStop, isFalse);
  });

  test('start, stop and resume move through the states', () async {
    final c = make(fastMock());
    await c.load();

    await c.start();
    expect(c.state, MachineRunState.running);
    expect(c.canStart, isFalse);
    expect(c.canStop, isTrue);

    await c.stop();
    expect(c.state, MachineRunState.stopped);
    expect(c.canStart, isTrue); // Start/Resume continues
    expect(c.canStop, isFalse);

    await c.start();
    expect(c.state, MachineRunState.running);
  });

  test('only one command is sent at a time', () async {
    final service = _ControlledService();
    final c = make(service);
    await c.load();

    final first = c.start();
    expect(c.sending, MachineCommand.start);
    expect(c.canStart, isFalse);
    expect(c.canStop, isFalse);

    await c.start(); // ignored while the first one is in flight
    expect(service.startCalls, 1);

    service.startAnswer.complete(MachineRunState.running);
    await first;

    expect(c.sending, isNull);
    expect(c.state, MachineRunState.running);
  });

  test('a failed command is reported and the state stays', () async {
    final c = make(_FailingService(MachineControlFailure.machineOffline));
    await c.load();

    await c.start();

    expect(c.commandFailure, MachineControlFailure.machineOffline);
    expect(c.state, MachineRunState.idle);
    expect(c.sending, isNull);
    expect(c.canStart, isTrue); // can try again
  });

  test('a new command clears the previous failure', () async {
    final c = make(_FailingService(MachineControlFailure.serverError));
    await c.load();
    await c.start();
    expect(c.commandFailure, isNotNull);

    final retry = c.start();
    expect(c.commandFailure, isNull);
    await retry;
  });

  test('a failure while loading the state is reported and load can retry',
      () async {
    final c = make(_FailingService(MachineControlFailure.unauthorized,
        statusWorks: false));

    await c.load();

    expect(c.loadFailure, MachineControlFailure.unauthorized);
    expect(c.state, isNull);
    expect(c.canStart, isFalse);
    expect(c.loading, isFalse);
  });
}
