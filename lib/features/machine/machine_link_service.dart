import 'machine_models.dart';

/// Talks to the machine over Bluetooth.
///
/// The UI only depends on this interface, so the real Bluetooth transport can
/// be added later without touching any screen.
abstract class MachineLinkService {
  /// Emits the growing list of machines found nearby and completes when the
  /// scan ends. Errors are [MachineLinkException]s.
  Stream<List<DiscoveredMachine>> scan();

  /// Connects to the machine and checks its password. Throws
  /// [MachineLinkException] (for example `wrongPassword`) on failure.
  Future<void> authenticate({
    required String machineId,
    required String password,
  });

  /// Sends the Wi-Fi details (when given) and waits, asynchronously, for the
  /// machine to confirm. Emits each [LinkStep] and finishes after
  /// [LinkStep.done]. Errors are [MachineLinkException]s.
  Stream<LinkStep> link({
    required DiscoveredMachine machine,
    WifiCredentials? wifi,
  });
}

/// Used when the simulated machine is turned off and the real Bluetooth
/// transport does not exist yet: every call fails with `notImplemented`.
class UnavailableMachineLinkService implements MachineLinkService {
  const UnavailableMachineLinkService();

  static const _error =
      MachineLinkException(MachineLinkFailure.notImplemented);

  @override
  Stream<List<DiscoveredMachine>> scan() =>
      Stream<List<DiscoveredMachine>>.error(_error);

  @override
  Future<void> authenticate({
    required String machineId,
    required String password,
  }) =>
      Future<void>.error(_error);

  @override
  Stream<LinkStep> link({
    required DiscoveredMachine machine,
    WifiCredentials? wifi,
  }) =>
      Stream<LinkStep>.error(_error);
}
