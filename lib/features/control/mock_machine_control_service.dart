import 'control_models.dart';
import 'machine_control_service.dart';

/// Simulated machine, so the screen works without a server. It remembers each
/// machine's state while the app is open.
class MockMachineControlService implements MachineControlService {
  MockMachineControlService({this.latency = const Duration(milliseconds: 600)});

  /// Simulated network time. Tests use [Duration.zero].
  final Duration latency;

  final Map<String, MachineRunState> _states = {};

  Future<void> _wait() async {
    if (latency > Duration.zero) await Future<void>.delayed(latency);
  }

  @override
  Future<MachineRunState> status(String machineId) async {
    await _wait();
    return _states[machineId] ?? MachineRunState.idle;
  }

  @override
  Future<MachineRunState> start(String machineId) async {
    await _wait();
    return _states[machineId] = MachineRunState.running;
  }

  @override
  Future<MachineRunState> stop(String machineId) async {
    await _wait();
    final current = _states[machineId] ?? MachineRunState.idle;
    // Stopping a machine that is not running changes nothing.
    if (current != MachineRunState.running) return current;
    return _states[machineId] = MachineRunState.stopped;
  }
}
