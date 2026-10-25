import 'dart:async';

import 'package:flutter/foundation.dart';

import 'machine_link_service.dart';
import 'machine_models.dart';

enum LinkPhase {
  deviceList,
  password,
  wifiQuestion,
  wifiForm,
  linking,
  success,
  failure,
}

typedef LinkedCallback = void Function(
  LinkedMachine machine, {
  required bool wifiSent,
});

/// State machine of the "Link machine" screen (no widgets, easy to test):
///
/// scan -> pick a machine -> password -> send Wi-Fi? -> (Wi-Fi form) ->
/// wait for the machine to confirm -> success or failure.
class MachineLinkFlow extends ChangeNotifier {
  MachineLinkFlow(
    this._service, {
    required this.onLinked,
    this.linkTimeout = const Duration(seconds: 90),
  });

  final MachineLinkService _service;
  final LinkedCallback onLinked;
  final Duration linkTimeout;

  LinkPhase phase = LinkPhase.deviceList;

  // Scan
  bool scanning = false;
  List<DiscoveredMachine> machines = const [];
  MachineLinkFailure? scanFailure;

  // Password
  DiscoveredMachine? selected;
  bool checkingPassword = false;
  MachineLinkFailure? passwordFailure;

  // Linking
  WifiCredentials? _wifi;
  LinkStep? step;
  MachineLinkFailure? failure;
  LinkedMachine? linked;

  StreamSubscription<List<DiscoveredMachine>>? _scanSub;
  StreamSubscription<LinkStep>? _linkSub;
  bool _disposed = false;

  bool get sentWifi => _wifi != null;

  /// True while going back or closing the screen would interrupt something.
  bool get isBusy => checkingPassword || phase == LinkPhase.linking;

  /// Starts (or restarts) the whole flow with a fresh scan.
  void startScan() {
    _scanSub?.cancel();
    _linkSub?.cancel();
    phase = LinkPhase.deviceList;
    selected = null;
    machines = const [];
    scanFailure = null;
    passwordFailure = null;
    checkingPassword = false;
    failure = null;
    linked = null;
    step = null;
    _wifi = null;
    scanning = true;
    _notify();

    _scanSub = _service.scan().listen(
      (found) {
        machines = found;
        _notify();
      },
      onError: (Object error) {
        scanFailure = _failureOf(error);
        scanning = false;
        _notify();
      },
      onDone: () {
        scanning = false;
        _notify();
      },
    );
  }

  void select(DiscoveredMachine machine) {
    _scanSub?.cancel();
    scanning = false;
    selected = machine;
    passwordFailure = null;
    phase = LinkPhase.password;
    _notify();
  }

  void backToList() {
    selected = null;
    passwordFailure = null;
    phase = LinkPhase.deviceList;
    _notify();
  }

  void clearPasswordFailure() {
    if (passwordFailure == null) return;
    passwordFailure = null;
    _notify();
  }

  Future<void> submitPassword(String password) async {
    final machine = selected;
    if (machine == null || checkingPassword) return;
    checkingPassword = true;
    passwordFailure = null;
    _notify();
    try {
      await _service.authenticate(machineId: machine.id, password: password);
      phase = LinkPhase.wifiQuestion;
    } on MachineLinkException catch (e) {
      passwordFailure = e.failure;
    } finally {
      checkingPassword = false;
      _notify();
    }
  }

  /// Answers "Send Wi-Fi details?". `send: false` skips straight to linking.
  void answerWifiQuestion({required bool send}) {
    if (send) {
      phase = LinkPhase.wifiForm;
      _notify();
    } else {
      _startLinking(null);
    }
  }

  void backToWifiQuestion() {
    phase = LinkPhase.wifiQuestion;
    _notify();
  }

  void submitWifi(WifiCredentials credentials) => _startLinking(credentials);

  void _startLinking(WifiCredentials? wifi) {
    final machine = selected;
    if (machine == null) return;
    _wifi = wifi;
    step = null;
    failure = null;
    phase = LinkPhase.linking;
    _notify();

    _linkSub = _service
        .link(machine: machine, wifi: wifi)
        .timeout(
          linkTimeout,
          onTimeout: (sink) {
            sink.addError(
              const MachineLinkException(MachineLinkFailure.timeout),
            );
            sink.close();
          },
        )
        .listen(
      (event) {
        step = event;
        if (event == LinkStep.done) {
          final result = LinkedMachine(id: machine.id, name: machine.name);
          linked = result;
          phase = LinkPhase.success;
          onLinked(result, wifiSent: wifi != null);
        }
        _notify();
      },
      onError: (Object error) {
        failure = _failureOf(error);
        phase = LinkPhase.failure;
        _notify();
      },
    );
  }

  MachineLinkFailure _failureOf(Object error) =>
      error is MachineLinkException ? error.failure : MachineLinkFailure.unknown;

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _scanSub?.cancel();
    _linkSub?.cancel();
    super.dispose();
  }
}
