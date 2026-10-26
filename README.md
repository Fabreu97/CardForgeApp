# CardForge

Mobile app (Flutter/Dart) to monitor and manage an automatic **Magic: The
Gathering** card sorter.

The physical machine holds a stack of cards, pulls one at a time with a roller,
identifies it with a camera and drops it in one of six numbered folders according
to the sorting rule defined in the app. CardForge is the control panel for that
machine.

> **Status:** early development. Splash, authentication, machine linking, machine
> control, alerts, cards in folders and settings are in place. The remaining
> screens are in the [roadmap](#roadmap). Server data and the machine's Bluetooth
> run against simulations until the real backend and protocol exist (see
> [Simulated mode](#simulated-mode)).

**Contents:** [Quick start](#quick-start) ·
[Configuration (.env)](#configuration-env) · [Screens](#screens) ·
[API communication rules](#api-communication-rules) ·
[Google sign-in](#google-sign-in) · [Android setup](#android-setup) ·
[Project structure](#project-structure) · [Design system](#design-system) ·
[Testing](#testing) · [Roadmap](#roadmap)

## Quick start

Requirements:

- Flutter **3.22 or newer** (Dart 3.4+)
- Android Studio (Android SDK) and/or Xcode, depending on the target platform
- An emulator or phone (`flutter devices` lists what is available)

```bash
flutter pub get
flutter run
```

With no configuration the app runs in [simulated mode](#simulated-mode): you can
try every screen without a server or a machine. Sign in with any username or email
and a password of 6 or more characters.

## Configuration (.env)

The app reads its settings **when it is built**, from values passed with
`--dart-define`. The practical way is a `.env` file that you hand to Flutter with
`--dart-define-from-file`.

### Creating the file

1. Copy the example (it is in the project root):

   ```bash
   cp .env.example .env          # Windows: copy .env.example .env
   ```

2. Edit the values in `.env` (one `KEY=value` per line, no quotes needed):

   ```
   USE_MOCK=false
   USE_MOCK_BLUETOOTH=true
   API_BASE_URL=https://your-server.com
   GOOGLE_SERVER_CLIENT_ID=1234567890-abc.apps.googleusercontent.com
   ```

3. Keep it out of git: add this line to `.gitignore` (the `.env.example` stays in
   the repository).

   ```
   .env
   ```

4. Run with it:

   ```bash
   flutter run --dart-define-from-file=.env
   flutter build apk --dart-define-from-file=.env
   ```

The same flag works for `flutter build appbundle` and `flutter build ios`. To keep
one file per environment, create `.env.dev` and `.env.prod` and pick one per
command.

If your Flutter version does not accept `.env` files, use a JSON file instead (for
example `env.json` with `{"USE_MOCK": "false", "API_BASE_URL": "https://..."}`)
and the same `--dart-define-from-file=env.json` flag.

**VS Code:** add this to `.vscode/launch.json` so the Run button uses the file:

```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "CardForge (.env)",
      "request": "launch",
      "type": "dart",
      "toolArgs": ["--dart-define-from-file=.env"]
    }
  ]
}
```

**Android Studio:** Run > Edit Configurations > *Additional run args*:
`--dart-define-from-file=.env`.

### Variables

| Variable | Default | Description |
|---|---|---|
| `USE_MOCK` | `true` | `true` = simulated server (sign-in, `/health`, cards, machine control). `false` = the real server at `API_BASE_URL`. |
| `USE_MOCK_BLUETOOTH` | `true` | `true` = simulated machine for linking. `false` = real Bluetooth, which is not built yet (linking shows "not available"). |
| `API_BASE_URL` | `https://api.cardforge.example` | Server address, without a trailing slash. Every route is appended to it. |
| `GOOGLE_SERVER_CLIENT_ID` | empty | OAuth client ID of type *Web* (Google Cloud). Needed for Google sign-in to return the `idToken` on Android. |

They are read in `lib/core/config/app_config.dart`. The timeouts (5 s for `/health`
and sign-in, 10 s for other requests, 90 s to link a machine) are constants in the
same file.

### Good to know

- The values are **compiled into the app**, so anyone can extract them from the
  installed app. Put only public settings there (a URL, the Google *Web* client
  ID), never passwords or private keys.
- After changing `.env`, **stop and run again**: hot reload does not pick up new
  values.
- `flutter test` ignores `.env` and always uses the simulated services.

### Simulated mode

By default no server or machine is needed:

- **Server (`USE_MOCK=true`):** any valid sign-in works, `/health` always answers,
  there are 36 sample cards in the six folders, and the machine remembers
  Start/Stop while the app is open. Searching cards for `fail` simulates a server
  error.
- **Machine (`USE_MOCK_BLUETOOTH=true`):** two machines are "found",
  `CardForge-A1B2` and `CardForge-9F3C`. Machine password `0000` is rejected (any
  other works) and a Wi-Fi network named `fail` makes the machine fail to join.

## Screens

| Screen | Route | Menu | What it does | Server calls |
|---|---|---|---|---|
| Splash | `/splash` | n/a | Checks the server and decides where to go: Login (no session) or Home (saved session). If the server does not answer it shows an error with **Try again**. | `GET /health` |
| Login | `/login` | n/a | Username or email + password, **Remember me** and Google sign-in. | `POST /auth/login`, `POST /auth/google` |
| Home | `/home` | n/a | Shows the linked machine (or a **Link machine** button), the alerts bell with an unread badge and the side menu. | none |
| Link machine | `/link-machine` | 1st | Wizard: Bluetooth scan, pick a machine, machine password, optional Wi-Fi details, wait for the machine to confirm. | none yet (Bluetooth) |
| Machine control | `/control` | 2nd | Two big buttons, **Start/Resume** and **Stop**, plus the machine's state. | `GET /machines/{id}/status`, `POST /machines/{id}/start`, `POST /machines/{id}/stop` |
| Cards in folders | `/cards` | 3rd | Search a card by name and see which folders (1 to 6) it is in; with nothing typed, lists the cards in the folders. | `GET /cards` |
| Alerts | `/alerts` | Alerts | Every event reported by the machine, newest first. Tap to mark as read, or mark/clear all. | none yet |
| Settings | `/settings` | Settings | Language (English or Portuguese) and, in debug builds only, a tool to simulate alerts. | none |

The side menu order is: **Link machine**, Machine control, Cards in folders, CSV
report, Sorting rules, Alerts, Settings and Sign out. CSV report and Sorting rules
have no screen yet and show a "coming soon" message.

```
Splash -- server ok? -- no --> Splash (error) -- Try again --+
   |                                ^------------------------+
  yes
   |
saved token? -- yes --> Home <---------------------------+
   |                     |  menu: Link machine, Machine  |
   no                    |  control, Cards, Alerts,      |
   |                     |  Settings                     |
 Login -- success -------+                               |
```

Every screen shows the row of five gold-framed symbols at the top.

### Language

The app starts in English. **Settings > Language** switches the whole app to
Portuguese and remembers the choice.

- All text lives in `lib/core/l10n/`: `app_strings.dart` declares every string,
  `strings_en.dart` and `strings_pt.dart` implement them. A missing translation
  fails the build, so nothing shows up blank.
- In a widget: `context.l10n.signIn`.
- **Adding a text:** declare it in `AppStrings`, then implement it in both
  languages. **Adding a language:** create a new `AppStrings` subclass and register
  it in `AppStrings.supportedLocales` and `AppStrings.forLocale`.

### Machine linking

From **Home > Link machine** (or the side menu):

1. The app scans over Bluetooth for CardForge machines (the Raspberry Pi) and lists
   them with their signal strength.
2. The user selects one and enters the **machine password**.
3. The app asks whether to **send the Wi-Fi details** (network name and password).
   The user can skip this.
4. The app waits, asynchronously, for the machine to confirm. It shows each step
   (sending Wi-Fi, waiting for the machine to join the network, linking to the
   account) and gives up after 90 seconds.
5. On success the machine is saved on the phone and alerts are raised ("Machine
   linked" and, if Wi-Fi was sent, "Machine connected to Wi-Fi"). On failure the
   user sees why and can try again.

The screen only draws each step; the logic is in `MachineLinkFlow`. The Bluetooth
side is behind the `MachineLinkService` interface, so the real transport can be
added without touching any screen. The real protocol is not defined yet.

### Machine control

Two big buttons, **Start/Resume** and **Stop**, and the machine's state (**Ready**,
**Running** or **Stopped**).

- **Start/Resume** is available when the machine is ready or stopped; it starts a
  run or continues a stopped one. **Stop** is available only while it is running.
- While a command is being sent both buttons are disabled and the pressed one shows
  a spinner. The state shown is always the one the server confirmed.
- On entering the screen the app asks the server for the current state, so it is
  right even if the run was started earlier or from another phone.
- Errors: machine offline, no connection, server problem, or an expired session
  (**Sign in again**). Without a linked machine the buttons are off and **Link
  machine** is one tap away.

### Cards in folders

The machine has **six folders, numbered 1 to 6**. The screen has a search bar on
top and the cards below it:

- **Nothing typed:** lists the cards that are in the folders (alphabetical), each
  with the folders it is in and how many copies are in each.
- **Searching by name:** lists the matching cards and the folders each one is in. A
  card can be in more than one folder.
- The search waits 400 ms after the last keystroke (or the keyboard's search key),
  results load in pages of 30 as you scroll, and pull-to-refresh reloads the list.
  An answer to an old search never replaces the newer one.
- Errors: no connection or a server problem shows **Try again**; an expired session
  shows **Sign in again**.

### Alerts

Alerts are events from the machine, shown in two places: a **banner** over whatever
screen is open (with a **View** button) and the **Alerts** screen (from the bell or
the menu).

Types: Wi-Fi connected, Wi-Fi lost, sorting finished, card jam, double feed,
connection lost and machine linked.

- An alert stores its type and data (machine name, card count), not text, so it is
  translated when shown and follows the current language.
- Alerts live in memory for now. When the server connection exists (push,
  WebSocket or polling), it only has to call `AlertsController.add(...)`.
- **Adding a type:** add it to `AlertType` (and its severity), then the title and
  message in both languages, plus an icon in `alert_style.dart`.
- In debug builds, **Settings > Developer tools** creates each alert on demand.

## API communication rules

### General rules

| Rule | Detail |
|---|---|
| Address | `API_BASE_URL` (see [Configuration](#configuration-env)) + the route, e.g. `https://your-server.com/cards` |
| Format | JSON in UTF-8, in requests and answers |
| Authentication | After sign-in the app sends `Authorization: Bearer <access_token>` on `/cards` and `/machines/...`. `/health` and `/auth/...` are sent without a token. |
| Token storage | In the device's secure storage; only in memory when **Remember me** is unchecked |
| Timeouts | 5 s for `/health` and sign-in; 10 s for `/cards` and `/machines/...` |
| Paging | `limit` and `offset`; the answer carries `total` (the number of matches, not the page size). The app asks 30 at a time. |
| Search | Optional `query`: part of the card name, any case. Left out when nothing is typed. |
| Folders | Numbers 1 to 6. Entries outside that range, or with a quantity below 1, are ignored. |
| Machine id | Put in the path, URL-encoded (the Bluetooth address contains `:`) |

### Endpoints

| Method and route | Request | Answer |
|---|---|---|
| `GET /health` | none | `200` if the server is up (the body is ignored) |
| `POST /auth/login` | `{"identifier": "...", "password": "..."}` (username or email) | `200` `{"access_token": "..."}` |
| `POST /auth/google` | `{"id_token": "..."}` (validate it with Google before answering) | `200` `{"access_token": "..."}` |
| `GET /cards?query=&limit=&offset=` | none | `200` `{"items": [card], "total": N}` |
| `GET /machines/{id}/status` | none | `200` `{"state": "idle" \| "running" \| "stopped"}` |
| `POST /machines/{id}/start` | none | `200` `{"state": ...}` with the new state (`running`) |
| `POST /machines/{id}/stop` | none | `200` `{"state": ...}` with the new state (`stopped`) |

Card as it comes in `items`:

```json
{
  "id": "c-123",
  "name": "Lightning Bolt",
  "folders": [
    { "folder": 4, "quantity": 4 },
    { "folder": 6, "quantity": 1 }
  ]
}
```

Examples to test a backend:

```bash
curl https://your-server.com/health

curl -X POST https://your-server.com/auth/login \
  -H 'Content-Type: application/json' \
  -d '{"identifier": "fernando@email.com", "password": "secret123"}'

curl 'https://your-server.com/cards?query=bolt&limit=30&offset=0' \
  -H 'Authorization: Bearer <access_token>'

curl -X POST https://your-server.com/machines/B8%3A27%3AEB%3A00%3AA1%3AB2/start \
  -H 'Authorization: Bearer <access_token>'
```

### Status codes and what the app does

| Where | Answer | App behavior |
|---|---|---|
| Any request | no answer, timeout, DNS failure | "Cannot reach the server" with **Try again** (Splash: "Could not reach the server") |
| `/auth/login`, `/auth/google` | `200` | Saves the token and opens Home |
| `/auth/login`, `/auth/google` | `401` | "Invalid username or password." |
| `/auth/login`, `/auth/google` | other | "Server error. Please try again." |
| `/cards`, `/machines/...` | `401` | "Your session expired" with **Sign in again** (signs out and goes to Login) |
| `/machines/...` | `409` | "The machine is offline. Check that it is on and connected to Wi-Fi." |
| `/cards`, `/machines/...` | other non-`200`, or an answer the app cannot read | "The server had a problem. Please try again." |

### Changing the API (routes and fields)

Every server route, query name, JSON field name, status code and state value is in
**one file: `lib/core/api/api_contract.dart`**. The services and models read from
it, so adapting the app to your backend usually means editing only that file:

| To change... | Edit in `api_contract.dart` |
|---|---|
| A path (e.g. `/api/v1/cards`) | `ApiRoutes.cards`, `ApiRoutes.login`, `ApiRoutes.machineStart`, ... |
| A query name (e.g. `q` instead of `query`) | `ApiQuery.search` |
| A JSON field (e.g. `title` instead of `name`) | `ApiFields.cardName`, `ApiFields.machineState`, ... |
| A state value (e.g. `paused` instead of `stopped`) | `ApiValues.stateStopped` |
| What a status code means | `ApiStatus.unauthorized`, `ApiStatus.machineOffline` |

The server address is not in that file (it is `API_BASE_URL`). The screen routes of
the app (`/home`, `/cards`, ...) are a different thing and live in
`lib/core/router/app_router.dart`.

If the *structure* of an answer changes (for example the server wraps everything in
`{"data": ...}`), change where it is read: `card_models.dart` for cards,
`api_machine_control_service.dart` for the machine state and `auth_service.dart` for
sign-in. The API tests build their data from the same constants, and
`test/core/api/api_contract_test.dart` checks that the routes are well formed (they
start with `/` and the machine routes keep their `{id}`).

### Not defined yet

These parts have no server contract or protocol, so they are simulated or local:

- the Bluetooth protocol of the machine (BLE or classic, services, message format);
- the call that links a machine to the user's account (today it is only saved on
  the phone);
- how alerts reach the app (push, WebSocket or polling);
- sorting rules and the CSV report.

## Google sign-in

The code is ready; the configuration lives outside it:

1. In Google Cloud Console create OAuth credentials: a **Web** client (its ID goes
   in `GOOGLE_SERVER_CLIENT_ID`), an **Android** client with the package name and
   the certificate SHA-1, and an **iOS** client if you target iOS.
2. Debug SHA-1: `cd android && ./gradlew signingReport`.
3. On iOS, add the client ID and URL scheme to `Info.plist`.
4. On the backend, validate the `id_token` received at `POST /auth/google` before
   issuing your own token.

The button uses a generic icon. Replace it with the official Google logo (asset)
before publishing.

## Android setup

- **`minSdk`:** `flutter_secure_storage` needs at least 23. In
  `android/app/build.gradle` (or `.kts`) set `minSdk = 23`.
- **Internet in release builds:** add
  `<uses-permission android:name="android.permission.INTERNET"/>` to
  `android/app/src/main/AndroidManifest.xml`, before `<application>`. Without it,
  API calls and the font download fail outside debug.
- **Local server from the emulator:** use `http://10.0.2.2:PORT` instead of
  `localhost` in `API_BASE_URL`. Because it is plain HTTP, add
  `android:usesCleartextTraffic="true"` to `<application>` during development.
  Remove it for production and use HTTPS.
- **Bluetooth (when the real transport is added):** the app will also need the
  Bluetooth scan/connect permissions in the manifest and at runtime.

## Project structure

```
lib/
├── main.dart                         Entry point
├── app.dart                          MaterialApp, language, alert banners
├── core/
│   ├── api/api_contract.dart         Server routes, query names, JSON fields
│   ├── app_scope.dart                Shared objects (language, alerts, machine)
│   ├── config/app_config.dart        Settings read from the .env values
│   ├── l10n/                         Strings (EN and PT) and language controller
│   ├── router/app_router.dart        Screen routes (go_router)
│   ├── services/server_health_service.dart
│   ├── theme/app_theme.dart          Colors (MagicColors) and Material theme
│   └── widgets/                      Design system components
└── features/
    ├── splash/
    ├── auth/                         AuthService + login screen
    ├── home/
    ├── settings/
    ├── alerts/                       Model, controller, banner style, screen
    ├── cards/                        Models, repository (API + mock), controller, screen
    ├── control/                      Start/Stop service (API + mock), controller, screen
    └── machine/                      Models, service interface, mock, flow, screen

assets/images/                        mana_symbols.png (transparent background)
test/                                 Tests (see Testing)
docs/diagrams.md                      Diagrams (Mermaid)
.env.example                          Template for your .env
```

Each screen lives in a folder under `features/`; anything shared lives in `core/`.

## Design system

Dark theme with a gold frame, the gold-framed symbols at the top and **Cinzel**
headings (through `google_fonts`; the font is downloaded the first time, so it needs
internet). There are no official game art or mana symbols, only generic fantasy
elements and a stylized symbol image.

| Token (`MagicColors`) | Color | Use |
|---|---|---|
| `background` | `#0E0B1A` | Screen background |
| `surface` | `#1A1530` | Fields and panels |
| `gold` | `#D4AF37` | Main button, icons, links |
| `goldSoft` | gold at 50% | Borders and dividers |
| `parchment` | `#F3E6C4` | Main text |
| `danger` | `#E5645A` | Errors |

Always use `MagicColors` and `Theme.of(context)`; no loose colors in screens.

- **`MagicScaffold`:** base of every screen, with the dark background and the
  symbols row below the app bar.
- **`MagicPanel`:** dark purple panel with a gold border, to group content.
- **`MagicWordmark`:** the "CARDFORGE" title.
- **`CardEmblem`:** the fanned cards.
- **`MagicSymbols`:** the row of five gold-framed symbols (sun, drop, skull, flame,
  tree), a PNG with a transparent background in `assets/images/`. Every
  `MagicScaffold` shows it below the app bar; pass `showSymbols: false` to hide it.

### Creating a new screen

1. Create `lib/features/<name>/<name>_screen.dart`.
2. Use `MagicScaffold` as the base and `MagicPanel` to group content.
3. Put every text in `AppStrings` (English and Portuguese).
4. Register the route in `lib/core/router/app_router.dart`.
5. Hook up the menu item in `home_screen.dart`.

## Testing

```bash
flutter test                   # run everything
flutter test test/features     # screens and logic only
flutter test --coverage        # writes coverage/lcov.info
```

Tests use the simulated services, the simulated secure storage and
`SharedPreferences.setMockInitialValues`, so they need no server, emulator,
internet or `.env`.

| Area | What it covers |
|---|---|
| `core/api` | The API contract file is well formed |
| `core/l10n` | Every enum value has text in both languages; language persistence |
| `core/widgets` | Design system components |
| `features/auth` | Session, token and "Remember me"; login validation and sign-in |
| `features/splash` | Destination by session, server error and "Try again" |
| `features/home` | Linked or not, side menu and its order, bell badge, sign out |
| `features/machine` | Linking state machine (timeout and errors), the screen end to end, saved machine |
| `features/control` | Start/Resume and Stop rules, API and simulated services, the screen |
| `features/cards` | Models, API and simulated repositories, search/paging controller, the screen |
| `features/alerts` | Controller, list, read state, banner |
| `features/settings` | Language switch and persistence, alert simulator |

Use `pumpApp(tester, initialLocation: '/route')` to open a screen. Options:
`preferences` (e.g. `{'language_code': 'pt'}`), `linkService`, `cardRepository`,
`machineControl` and `healthService` to swap the services.

## Roadmap

- [x] Splash with server check
- [x] Authentication (username/email + password, Google, remember me)
- [x] English UI with a language setting (English/Portuguese)
- [x] Machine linking over Bluetooth (simulated transport)
- [x] Alerts: banner and alerts screen
- [x] Cards in folders (search and list from the server)
- [x] Machine control: Start/Resume and Stop
- [x] Settings from a `.env` file
- [x] Automated tests
- [ ] Real Bluetooth transport (needs the machine's protocol)
- [ ] Machine progress and a Pause command
- [ ] Sorting rules
- [ ] CSV report
- [ ] Alerts from the server (push or WebSocket)
- [ ] Sign-up and password recovery

## Dependencies

| Package | Use |
|---|---|
| `go_router` | Navigation |
| `http` | API calls |
| `google_sign_in` (6.x) | Google sign-in |
| `flutter_secure_storage` | Session token |
| `shared_preferences` | Language and linked machine |
| `google_fonts` | Cinzel headings |
| `flutter_localizations` | Material text in Portuguese |

Keep `google_sign_in` on 6.x: version 7 changed the API and needs changes in
`auth_service.dart`.