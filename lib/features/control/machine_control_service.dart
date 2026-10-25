import 'control_models.dart';

/// Sends commands to the machine and reads its state.
///
/// The screen only knows this interface, so the simulated machine and the real
/// server are interchangeable.
abstract class MachineControlService {
  /// Current state of the machine. Throws [MachineControlException].
  Future<MachineRunState> status(String machineId);

  /// Starts a run, or continues one that was stopped. Returns the new state.
  Future<MachineRunState> start(String machineId);

  /// Stops the machine. Returns the new state.
  Future<MachineRunState> stop(String machineId);
}
