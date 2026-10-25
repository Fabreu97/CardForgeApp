import 'package:flutter/foundation.dart';

import '../machine/machine_models.dart';
import 'control_models.dart';
import 'machine_control_service.dart';

/// State of the "Machine control" screen (no widgets, easy to test).
///
/// - "Start/Resume" is available when the machine is ready or stopped.
/// - "Stop" is available while it is running.
/// - Only one command can be in flight at a time.
class MachineControlController extends ChangeNotifier {
  MachineControlController(this._service, this.machine);

  final MachineControlService _service;

  /// The linked machine, or null when none is linked yet.
  final LinkedMachine? machine;

  /// Null until the first status answer arrives.
  MachineRunState? state;

  /// True while the status is being loaded.
  bool loading = false;

  /// The command being sent, if any.
  MachineCommand? sending;

  /// Why the status could not be loaded.
  MachineControlFailure? loadFailure;

  /// Why the last command failed. Cleared when a new command starts.
  MachineControlFailure? commandFailure;

  bool _disposed = false;

  bool get hasMachine => machine != null;
  bool get _ready => hasMachine && !loading && sending == null && state != null;

  bool get canStart =>
      _ready &&
      (state == MachineRunState.idle || state == MachineRunState.stopped);
  bool get canStop => _ready && state == MachineRunState.running;

  /// Reads the machine state (also used to try again after a failure).
  Future<void> load() async {
    final target = machine;
    if (target == null) return;
    loading = true;
    loadFailure = null;
    _notify();
    try {
      state = await _service.status(target.id);
    } on MachineControlException catch (e) {
      loadFailure = e.failure;
    } catch (_) {
      loadFailure = MachineControlFailure.serverError;
    }
    loading = false;
    _notify();
  }

  Future<void> start() => _send(MachineCommand.start);

  Future<void> stop() => _send(MachineCommand.stop);

  Future<void> _send(MachineCommand command) async {
    final allowed = command == MachineCommand.start ? canStart : canStop;
    final target = machine;
    if (!allowed || target == null) return;

    sending = command;
    commandFailure = null;
    _notify();
    try {
      state = command == MachineCommand.start
          ? await _service.start(target.id)
          : await _service.stop(target.id);
    } on MachineControlException catch (e) {
      commandFailure = e.failure;
    } catch (_) {
      commandFailure = MachineControlFailure.serverError;
    }
    sending = null;
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
