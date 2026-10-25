import 'machine_link_service.dart';
import 'machine_models.dart';

/// Simulated machines, so the whole linking flow works in the emulator
/// (which has no Bluetooth).
///
/// Try the error states:
/// - machine password `0000` is rejected;
/// - Wi-Fi network named `fail` makes the machine fail to connect.
class MockMachineLinkService implements MachineLinkService {
  MockMachineLinkService({this.stepDelay = const Duration(milliseconds: 900)});

  /// Pause between simulated events. Tests use [Duration.zero].
  final Duration stepDelay;

  static const String rejectedPassword = '0000';
  static const String failingNetwork = 'fail';

  static const List<DiscoveredMachine> _machines = [
    DiscoveredMachine(
      id: 'B8:27:EB:00:A1:B2',
      name: 'CardForge-A1B2',
      signalDbm: -48,
    ),
    DiscoveredMachine(
      id: 'B8:27:EB:00:9F:3C',
      name: 'CardForge-9F3C',
      signalDbm: -72,
    ),
  ];

  Future<void> _wait([int times = 1]) =>
      Future<void>.delayed(stepDelay * times);

  @override
  Stream<List<DiscoveredMachine>> scan() async* {
    final found = <DiscoveredMachine>[];
    for (final machine in _machines) {
      await _wait();
      found.add(machine);
      yield List<DiscoveredMachine>.of(found);
    }
    await _wait();
  }

  @override
  Future<void> authenticate({
    required String machineId,
    required String password,
  }) async {
    await _wait();
    if (password == rejectedPassword) {
      throw const MachineLinkException(MachineLinkFailure.wrongPassword);
    }
  }

  @override
  Stream<LinkStep> link({
    required DiscoveredMachine machine,
    WifiCredentials? wifi,
  }) async* {
    if (wifi != null) {
      yield LinkStep.sendingWifi;
      await _wait();
      if (wifi.ssid.toLowerCase() == failingNetwork) {
        throw const MachineLinkException(MachineLinkFailure.wifiFailed);
      }
      yield LinkStep.waitingForWifi;
      await _wait(3); // the machine takes a while to join the network
    }
    yield LinkStep.linkingAccount;
    await _wait();
    yield LinkStep.done;
  }
}
