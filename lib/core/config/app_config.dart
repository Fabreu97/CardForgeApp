/// Global settings.
/// To point the app at the real server:
///   flutter run --dart-define=USE_MOCK=false --dart-define=API_BASE_URL=https://your-server.com
class AppConfig {
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api.cardforge.example',
  );

  /// While the backend does not exist, the app runs on simulated responses.
  static const bool useMockBackend = bool.fromEnvironment(
    'USE_MOCK',
    defaultValue: true,
  );

  /// The real Bluetooth transport is not implemented yet, so the machine
  /// linking flow runs against a simulated machine by default.
  static const bool useMockBluetooth = bool.fromEnvironment(
    'USE_MOCK_BLUETOOTH',
    defaultValue: true,
  );

  /// OAuth client ID of type "Web" from Google Cloud. On Android, Google only
  /// returns the idToken (which the backend validates) when this is set.
  static const String googleServerClientId =
      String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID');

  static const Duration healthTimeout = Duration(seconds: 5);

  /// Timeout for regular API requests (card search, etc.).
  static const Duration requestTimeout = Duration(seconds: 10);
  static const Duration splashMinDuration = Duration(milliseconds: 1500);

  /// How long to wait for the machine to confirm the link before giving up.
  static const Duration linkTimeout = Duration(seconds: 90);
}
