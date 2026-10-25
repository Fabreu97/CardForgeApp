# CLAUDE.md

Guidance for working on this repository.

## What this is

CardForge is a Flutter/Dart mobile app that monitors and controls a physical
machine that sorts Magic: The Gathering cards (a roller pulls one card at a time,
a camera identifies it, and it is placed in one of six numbered folders by rules
set in the app). Read `README.md` for the screens, the backend contract and the
roadmap, and `docs/diagrams.md` for the flows.

## Commands

```bash
flutter pub get
flutter analyze
flutter test                          # all tests
flutter test test/features/cards      # one folder
flutter test --coverage
flutter run                           # simulated backend and machine (default)
flutter run \
  --dart-define=USE_MOCK=false \
  --dart-define=API_BASE_URL=https://your-server.com \
  --dart-define=GOOGLE_SERVER_CLIENT_ID=<web client id>
```

Requires Flutter 3.22+ (Dart 3.4+). Keep `google_sign_in` on 6.x: 7.x changed the
API.

Build-time flags live in `lib/core/config/app_config.dart`:

| Flag | Default | Effect |
|---|---|---|
| `USE_MOCK` | `true` | Simulated server: sign-in, `/health` and `/cards` |
| `USE_MOCK_BLUETOOTH` | `true` | Simulated machine for linking |
| `API_BASE_URL` | placeholder | Real API base URL |
| `GOOGLE_SERVER_CLIENT_ID` | empty | Needed for the Google `idToken` on Android |

Handy simulated behaviors: machine password `0000` is rejected, a Wi-Fi network
named `fail` makes the machine fail to join, and searching cards for `fail`
returns a server error. The simulated machine control remembers Start/Stop
while the app is open.

## Architecture

- **Startup:** `main.dart` loads `SharedPreferences`, builds `AppDependencies`
  and runs `CardForgeApp` (`app.dart`), which owns the router, the language and
  the alert banners.
- **Shared objects:** `AppDependencies` (in `core/app_scope.dart`) holds
  `locale` (`LocaleController`), `alerts` (`AlertsController`), `machineStore`,
  `linkService`, `cardRepository`, `machineControl` and the `messengerKey`. Screens read them with
  `AppScope.of(context)`, which does not register a dependency, so it is safe in
  `initState`; listen to the specific controller with `ListenableBuilder`.
- **Routes** are in `core/router/app_router.dart` (`createAppRouter`): `/splash`,
  `/login`, `/home`, `/link-machine`, `/alerts`, `/settings`, `/cards`, `/control`.
- **Features** live in `lib/features/<name>/`: `splash`, `auth`, `home`,
  `settings`, `alerts`, `machine`, `cards`, `control`. Logic that is more than trivial sits
  in a `ChangeNotifier` or plain class next to the screen, not in the widget:
  `MachineLinkFlow` (linking state machine), `CardsInFoldersController` (search
  debounce, paging, ignores out-of-order answers), `AlertsController`.
- **Talking to the outside** goes through interfaces with a simulated and a real
  implementation: `CardRepository` (`ApiCardRepository` / `MockCardRepository`)
  and `MachineLinkService` (`MockMachineLinkService` /
  `UnavailableMachineLinkService`) and `MachineControlService`
  (`ApiMachineControlService` / `MockMachineControlService`). The real Bluetooth transport does not exist
  yet; the protocol is undefined.
- **Auth:** `AuthService` is a singleton. The token is kept in
  `flutter_secure_storage`, or only in memory when "Remember me" is off. Failures
  are `AuthFailure` values that the UI translates.
- **Alerts:** anything that calls `AlertsController.add(type, ...)` shows a
  banner over the current screen (built in `app.dart`) and appears in the Alerts
  screen. An alert stores its type and data, not text, so it follows the language.
- **Design system** (`lib/core/widgets`, `core/theme`): colors are `MagicColors`;
  every screen is a `MagicScaffold`, which shows the row of gold-framed symbols
  below the app bar (`showSymbols: false` hides it); `MagicPanel`, `MagicWordmark`, `CardEmblem`, `MagicSymbols`.

## Conventions

- **Code, names and comments are in English.** The UI starts in English and can
  switch to Portuguese in Settings.
- **Never hard-code UI text.** Add it to `AppStrings` (`core/l10n/app_strings.dart`)
  and implement it in both `strings_en.dart` and `strings_pt.dart`; a missing one
  fails the build. Use `context.l10n.something`. Texts that depend on a failure or
  type take the enum (e.g. `l10n.linkFailure(failure)`).
- **No loose colors or hex values in screens:** use `MagicColors` and
  `Theme.of(context)`.
- **New screen:** create `features/<name>/<name>_screen.dart` on a
  `MagicScaffold`, add its strings, register the route, link it from the menu in
  `home_screen.dart`, and write tests.
- **New alert type:** add it to `AlertType` (with its severity), the title and
  message in both languages, and an icon in `alert_style.dart`.
- `TextFormField` ignores `decoration.errorText` (the form's validator wins), so
  server-side errors are shown with a separate `Text` under the field.
- Avoid deprecated Material APIs; `Radio` is intentionally not used.

## Testing

- Tests use the simulated services and `SharedPreferences.setMockInitialValues`;
  they need no server, emulator or internet.
- Open any screen with `pumpApp(tester, initialLocation: '/route')` from
  `test/helpers/test_helpers.dart`. Options: `preferences` (e.g.
  `{'language_code': 'pt'}`), `linkService`, `cardRepository`, `healthService`.
  It returns the `AppDependencies` so tests can inspect them.
- Call `configureTestEnvironment` in `setUpAll` (stops google_fonts from
  downloading) and `resetAuthState()` when a test touches the session.
- Simulated services accept `Duration.zero` delays so tests finish quickly; the
  default delays are for the emulator.
- Tests for logic (`*_controller_test.dart`, `machine_link_flow_test.dart`) are
  plain `test`s; screens use `testWidgets`.

## Current state

- Done: Splash, authentication, language setting, machine linking (simulated
  Bluetooth), alerts, Cards in folders (search and list from the server), Machine
  control (Start/Resume and Stop), the
  mana-symbols header on every screen (it replaced the colored orbs).
- Not done: real Bluetooth transport, machine progress and a Pause command, CSV report, sorting rules,
  alerts coming from the server (push or WebSocket), sign-up and password
  recovery. Menu items without a screen show "coming soon".
- The code was written without being compiled by the assistant that produced it.
  Run `flutter analyze` and `flutter test` first and fix anything they report.
- `assets/images/mana_symbols.png` is a stylized version of Magic's mana symbols,
  which are trademarks of Wizards of the Coast. Replace it before publishing to a
  store.
