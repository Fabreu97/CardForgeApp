/// Why linking a machine (or searching for one) failed.
enum MachineLinkFailure {
  bluetoothUnavailable,
  wrongPassword,
  connectionLost,
  wifiFailed,
  accountLinkFailed,
  timeout,
  notImplemented,
  unknown,
}

class MachineLinkException implements Exception {
  const MachineLinkException(this.failure);

  final MachineLinkFailure failure;

  @override
  String toString() => 'MachineLinkException($failure)';
}

/// Progress reported by the machine while it is being linked.
enum LinkStep { sendingWifi, waitingForWifi, linkingAccount, done }

/// A CardForge machine found by the Bluetooth scan.
class DiscoveredMachine {
  const DiscoveredMachine({
    required this.id,
    required this.name,
    required this.signalDbm,
  });

  final String id;
  final String name;
  final int signalDbm;

  /// 3 = strong, 1 = weak.
  int get signalLevel => signalDbm >= -60
      ? 3
      : signalDbm >= -75
          ? 2
          : 1;
}

class WifiCredentials {
  const WifiCredentials({required this.ssid, required this.password});

  final String ssid;

  /// Empty for open networks.
  final String password;

  @override
  String toString() => 'WifiCredentials(ssid: $ssid)'; // never print the password
}

class LinkedMachine {
  const LinkedMachine({required this.id, required this.name});

  final String id;
  final String name;
}
