import 'package:cardforge/features/control/control_models.dart';
import 'package:cardforge/features/control/mock_machine_control_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late MockMachineControlService service;

  setUp(() => service = MockMachineControlService(latency: Duration.zero));

  test('a new machine is ready', () async {
    expect(await service.status('m1'), MachineRunState.idle);
  });

  test('start runs, stop stops, and start continues', () async {
    expect(await service.start('m1'), MachineRunState.running);
    expect(await service.status('m1'), MachineRunState.running);

    expect(await service.stop('m1'), MachineRunState.stopped);
    expect(await service.status('m1'), MachineRunState.stopped);

    expect(await service.start('m1'), MachineRunState.running);
  });

  test('stopping a machine that is not running changes nothing', () async {
    expect(await service.stop('m1'), MachineRunState.idle);
  });

  test('each machine has its own state', () async {
    await service.start('m1');

    expect(await service.status('m1'), MachineRunState.running);
    expect(await service.status('m2'), MachineRunState.idle);
  });

  test('parseRunState reads the three states and rejects anything else', () {
    expect(parseRunState('idle'), MachineRunState.idle);
    expect(parseRunState('running'), MachineRunState.running);
    expect(parseRunState('stopped'), MachineRunState.stopped);
    expect(parseRunState('paused'), isNull);
    expect(parseRunState(null), isNull);
  });
}
