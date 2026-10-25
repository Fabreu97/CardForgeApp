import '../../core/api/api_contract.dart';

/// What the machine is doing, as the app shows it.
enum MachineRunState {
  /// Ready: nothing is running.
  idle,

  /// Sorting cards.
  running,

  /// Stopped by the user; it can be continued.
  stopped,
}

/// Commands the app can send to the machine.
enum MachineCommand { start, stop }

/// Why a status request or a command failed.
enum MachineControlFailure {
  unauthorized,
  serverUnreachable,
  machineOffline,
  serverError,
}

class MachineControlException implements Exception {
  const MachineControlException(this.failure);

  final MachineControlFailure failure;

  @override
  String toString() => 'MachineControlException($failure)';
}

/// Reads the `state` field the server sends. Returns null for an unknown value.
MachineRunState? parseRunState(Object? value) => switch (value) {
      ApiValues.stateIdle => MachineRunState.idle,
      ApiValues.stateRunning => MachineRunState.running,
      ApiValues.stateStopped => MachineRunState.stopped,
      _ => null,
    };
