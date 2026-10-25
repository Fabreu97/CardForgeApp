/// Everything the app assumes about the server API, in one place.
///
/// If your backend uses other paths, query names, field names or values, change
/// them here; the services and models read them from this file.
///
/// What this file does NOT cover: a different *structure* of the answer (for
/// example wrapping it in `{"data": ...}`) needs a change where the answer is
/// read:
/// - cards and pages:     `lib/features/cards/card_models.dart`
/// - machine state:       `lib/features/control/api_machine_control_service.dart`
/// - sign-in answer:      `lib/features/auth/auth_service.dart`
///
/// The server address is not here either: it comes from
/// `--dart-define=API_BASE_URL=...` (see `lib/core/config/app_config.dart`).
/// The screen routes of the app live in `lib/core/router/app_router.dart`.
library;

/// Paths of the server endpoints (appended to `API_BASE_URL`).
///
/// A `{id}` in a path is replaced by the machine id; use [path] to fill it.
class ApiRoutes {
  ApiRoutes._();

  /// `GET`: answers `200` when the server is up.
  static const String health = '/health';

  /// `POST`: body `{identifier, password}`, answer `{access_token}`.
  static const String login = '/auth/login';

  /// `POST`: body `{id_token}`, answer `{access_token}`.
  static const String googleLogin = '/auth/google';

  /// `GET ?query=&limit=&offset=`: answer `{items: [...], total}`.
  static const String cards = '/cards';

  /// `GET`: answer `{state}`.
  static const String machineStatus = '/machines/{id}/status';

  /// `POST`: starts or continues the run. Answer `{state}`.
  static const String machineStart = '/machines/{id}/start';

  /// `POST`: stops the machine. Answer `{state}`.
  static const String machineStop = '/machines/{id}/stop';

  /// Fills the `{id}` of a route, encoding the id so it is safe in a URL.
  static String path(String route, {required String id}) =>
      route.replaceAll('{id}', Uri.encodeComponent(id));
}

/// Names of the query parameters of `GET /cards`.
class ApiQuery {
  ApiQuery._();

  /// Part of the card name to look for. Left out when nothing is typed.
  static const String search = 'query';
  static const String limit = 'limit';
  static const String offset = 'offset';
}

/// Request headers.
class ApiHeaders {
  ApiHeaders._();

  static const String authorization = 'Authorization';

  static String bearer(String token) => 'Bearer $token';
}

/// What the HTTP status codes mean to the app.
class ApiStatus {
  ApiStatus._();

  static const int ok = 200;

  /// The token is missing or expired: the user must sign in again.
  static const int unauthorized = 401;

  /// The machine is offline (answer of the Start/Stop/status routes).
  static const int machineOffline = 409;
}

/// Names of the fields in the JSON the app sends and receives.
class ApiFields {
  ApiFields._();

  // Sign-in (request and answer)
  static const String identifier = 'identifier';
  static const String password = 'password';
  static const String idToken = 'id_token';
  static const String accessToken = 'access_token';

  // Cards: a page of results
  static const String pageItems = 'items';
  static const String pageTotal = 'total';

  // Cards: one card and the folders it is in
  static const String cardId = 'id';
  static const String cardName = 'name';
  static const String cardFolders = 'folders';
  static const String folderNumber = 'folder';
  static const String folderQuantity = 'quantity';

  // Machine
  static const String machineState = 'state';
}

/// Values the server uses inside those fields.
class ApiValues {
  ApiValues._();

  // Machine state
  static const String stateIdle = 'idle';
  static const String stateRunning = 'running';
  static const String stateStopped = 'stopped';
}
