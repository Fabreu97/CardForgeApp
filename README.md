# CardForge

Mobile app (Flutter/Dart) to monitor and manage an automatic **Magic: The
Gathering** card sorter.

The physical machine holds a stack of cards, pulls one at a time with a roller,
identifies it with a camera and drops it in the right folder according to the
sorting rule defined in the app. CardForge is the control panel for that machine.

> **Status:** early development. Splash, authentication, machine linking, machine control,
> alerts, cards in folders and settings are in place. The remaining screens are listed in the
> [roadmap](#roadmap). Bluetooth runs against a simulated machine until the real
> transport is built (see [Machine linking](#machine-linking)).

## Screens

| Screen | Route | What it does |
|---|---|---|
| Splash | `/splash` | Checks the server (`GET /health`) and decides where to go: Login (no session) or Home (saved session). If the server does not answer it shows an error with **Try again**. |
| Login | `/login` | Username or email + password, **Remember me** and Google sign-in. |
| Home | `/home` | Shows the linked machine (or a **Link machine** button), the alerts bell with an unread badge and the side menu. |
| Link machine | `/link-machine` | Wizard: Bluetooth scan, pick a machine, machine password, optional Wi-Fi details, wait for the machine to confirm. |
| Alerts | `/alerts` | Every event reported by the machine, newest first. Tap to mark as read, or mark/clear all. |
| Machine control | `/control` | Two big buttons, **Start/Resume** and **Stop**, plus the machine's state (Ready, Running, Stopped). Commands go to the server. |
| Cards in folders | `/cards` | Search a card by name and see which folders (1 to 6) it is in; with nothing typed, lists the cards in the folders. Data comes from the server. |
| Settings | `/settings` | Language (English or Portuguese) and, in debug builds only, a tool to simulate alerts. |

Side-menu items that do not have a screen yet (CSV report, sorting rules) show a "coming soon" message. **Link machine** is the
first item of the side menu.

### Navigation flow

```
Splash -- server ok? -- no --> Splash (error) -- Try again --+
   |                                ^------------------------+
  yes
   |
saved token? -- yes --> Home <---------------------------+
   |                     |  menu: Link machine, Alerts,  |
   no                    |  Settings                     |
   |                     v                               |
 Login -- success -------+                               |
```

## Language

The app is written in English and starts in English. **Settings > Language**
switches the whole app to Portuguese and remembers the choice.

- All text lives in `lib/core/l10n/`: `app_strings.dart` declares every string,
  `strings_en.dart` and `strings_pt.dart` implement them. If a language misses a
  string, the build fails, so nothing shows up blank.
- In a widget: `context.l10n.signIn`.
- **Adding a text:** declare it in `AppStrings`, then implement it in both
  languages.
- **Adding a language:** create a new `AppStrings` subclass, then register it in
  `AppStrings.supportedLocales` and `AppStrings.forLocale`.

## Machine linking

After signing in, the user links a machine from **Home > Link machine** (or the
side menu):

1. The app scans over Bluetooth for CardForge machines (the Raspberry Pi) and
   lists them with their signal strength.
2. The user selects one and enters the **machine password**.
3. The app asks whether to **send the Wi-Fi details** (network name and
   password). The user can skip this.
4. The app waits, asynchronously, for the machine to confirm: it shows each step
   (sending Wi-Fi, waiting for the machine to join the network, linking to the
   account) and times out after 90 seconds.
5. On success the machine is saved on the phone and two alerts are raised
   ("Machine linked" and, if Wi-Fi was sent, "Machine connected to Wi-Fi"). On
   failure the user sees why and can try again.

The screen only draws each step. The logic is in `MachineLinkFlow`, and the
Bluetooth side is behind the `MachineLinkService` interface, so the real
transport can be added without touching any screen.

**What is real and what is simulated:** the real Bluetooth transport does not
exist yet. By default (`USE_MOCK_BLUETOOTH=true`) the app uses
`MockMachineLinkService`, which works in the emulator:

- two machines are "found": `CardForge-A1B2` and `CardForge-9F3C`;
- machine password `0000` is rejected, any other is accepted;
- a Wi-Fi network named `fail` makes the machine fail to connect.

With `USE_MOCK_BLUETOOTH=false` every Bluetooth call fails with "not available
in this build yet" until the real service is written.

## Alerts

Alerts are events from the machine, shown in two places: a **banner** over
whatever screen is open (with a **View** button) and the **Alerts** screen
(opened from the bell or the menu).

Available types: Wi-Fi connected, Wi-Fi lost, sorting finished, card jam, double
feed, connection lost and machine linked.

- An alert stores its type and data (machine name, card count), not text, so it
  is translated when shown and follows the current language.
- Alerts live in memory for now. When the server connection exists (push,
  WebSocket or polling), it only has to call `AlertsController.add(...)`.
- **Adding a type:** add it to `AlertType` (and its severity), then the title and
  message in both languages, plus an icon in `alert_style.dart`.
- In debug builds, **Settings > Developer tools** creates each alert on demand.

## Cards in folders

The machine has **six folders, numbered 1 to 6**. The screen has a search bar on
top and the cards below it:

- **Nothing typed:** lists the cards that are in the folders (alphabetical), each
  with the folders it is in and how many copies are there.
- **Searching by name:** lists the matching cards and the folders each one is in.
  A card can be in more than one folder.
- **Everything comes from the server** (`GET /cards`). The search waits 400 ms
  after the last keystroke (or the keyboard's search key), results load in pages
  of 30 as you scroll, and pull-to-refresh reloads the list. An answer to an old
  search never replaces the newer one.
- **Errors:** no connection or a server problem shows **Try again**; an expired
  session shows **Sign in again**.

With the simulated backend (the default) there are 36 sample cards spread over
the six folders. Searching for `fail` simulates a server error.

Expected response of `GET /cards?query=bolt&limit=30&offset=0` (`query` is left
out to list every card; the request carries `Authorization: Bearer <token>`):

```json
{
  "items": [
    {
      "id": "c-123",
      "name": "Lightning Bolt",
      "folders": [
        { "folder": 4, "quantity": 4 },
        { "folder": 6, "quantity": 1 }
      ]
    }
  ],
  "total": 1
}
```

`total` is the number of cards that match, not the size of the page. Folder
numbers outside 1 to 6 are ignored.

## Machine control

Two big buttons, **Start/Resume** and **Stop**, and the machine's state
(**Ready**, **Running** or **Stopped**).

- **Start/Resume** is available when the machine is ready or stopped, and starts a
  run or continues a stopped one. **Stop** is available while it is running and
  halts the machine.
- While a command is being sent both buttons are disabled and the pressed one
  shows a spinner. The state shown is always the one the server confirmed.
- On entering the screen the app asks the server for the current state, so it is
  right even if the run was started earlier or from another phone.
- Errors: machine offline (the server answers `409`), no connection, server
  problem, or an expired session (**Sign in again**).
- Without a linked machine the buttons are off and **Link machine** is one tap
  away.

With the simulated backend (the default) the machine remembers its state while the
app is open.

Server routes (each answers `200` with `{"state": "idle" | "running" |
"stopped"}`; `401` = session expired, `409` = machine offline):

```
GET  /machines/{id}/status
POST /machines/{id}/start
POST /machines/{id}/stop
```

## Requirements

- Flutter **3.22 or newer** (Dart 3.4+)
- Android Studio (Android SDK) and/or Xcode, depending on the target platform
- An emulator or phone (`flutter devices` lists what is available)

## Running

```bash
flutter pub get
flutter run
```

By default the app uses a **simulated backend** (`USE_MOCK=true`): the Splash
passes right away and any valid sign-in works (a username or email and a
password of 6+ characters). You can try every screen without a server.

### Pointing at the real server

```bash
flutter run \
  --dart-define=USE_MOCK=false \
  --dart-define=API_BASE_URL=https://your-server.com \
  --dart-define=GOOGLE_SERVER_CLIENT_ID=YOUR_WEB_CLIENT_ID.apps.googleusercontent.com
```

| Variable | Default | Description |
|---|---|---|
| `USE_MOCK` | `true` | Use simulated server responses. |
| `USE_MOCK_BLUETOOTH` | `true` | Use the simulated machine for linking. |
| `API_BASE_URL` | `https://api.cardforge.example` | API base URL. |
| `GOOGLE_SERVER_CLIENT_ID` | empty | OAuth client ID of type *Web* (Google Cloud). Needed for Google sign-in to return the `idToken` on Android. |

They are read in `lib/core/config/app_config.dart`.

## Backend contract

| Method and route | Body | Response |
|---|---|---|
| `GET /health` | n/a | `200` if the server is up |
| `POST /auth/login` | `{"identifier": "...", "password": "..."}` | `200` with `{"access_token": "..."}`, or `401` for invalid credentials |
| `POST /auth/google` | `{"id_token": "..."}` | `200` with `{"access_token": "..."}`; the backend validates the Google token |
| `GET /cards?query=&limit=&offset=` | n/a | `200` with `{"items": [...], "total": N}` (see [Cards in folders](#cards-in-folders)); `401` if the token is invalid |
| `GET /machines/{id}/status` | n/a | `200` with `{"state": "idle" \| "running" \| "stopped"}` (see [Machine control](#machine-control)) |
| `POST /machines/{id}/start` | n/a | Same answer, with the new state; `409` if the machine is offline |
| `POST /machines/{id}/stop` | n/a | Same answer, with the new state |

The token is kept in the device's secure storage (`flutter_secure_storage`). With
**Remember me** unchecked, the session lasts only until the app is closed.

If your backend uses other routes or formats, the change is limited to
`lib/features/auth/auth_service.dart` and
`lib/core/services/server_health_service.dart`.

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
  `localhost`. Because it is plain HTTP, add
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
│   ├── app_scope.dart                Shared objects (language, alerts, machine)
│   ├── config/app_config.dart        Environment variables (dart-define)
│   ├── l10n/                         Strings (EN and PT) and language controller
│   ├── router/app_router.dart        Routes (go_router)
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
```

Each screen lives in a folder under `features/`; anything shared lives in `core/`.

## Design system

Dark theme with a gold frame, the gold-framed symbols at the top and **Cinzel** headings
(through `google_fonts`; the font is downloaded the first time, so it needs
internet). There are no mana symbols or official game art, only generic fantasy
elements.

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
  Accepts a transparent `appBar` and a `drawer`.
- **`MagicPanel`:** dark purple panel with a gold border, to group content.
- **`MagicWordmark`:** the "CARDFORGE" title.
- **`CardEmblem`:** the fanned cards.
- **`MagicSymbols`:** the row of five gold-framed symbols (sun, drop, skull, flame,
  tree), a PNG with a transparent background in `assets/images/`. Every
  `MagicScaffold` shows it below the app bar; pass `showSymbols: false` to hide it.

## Creating a new screen

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

Tests use the simulated backend, the simulated secure storage and
`SharedPreferences.setMockInitialValues`, so they need no server, emulator or
internet.

| Area | What it covers |
|---|---|
| `features/auth` | Session, token and "Remember me"; login validation and sign-in |
| `features/splash` | Destination by session, server error and "Try again" |
| `features/home` | Linked or not, side menu, bell badge, sign out |
| `features/machine` | Linking state machine (including timeout and errors), the screen end to end, saved machine |
| `features/alerts` | Controller, list, read state, banner |
| `features/control` | Start/Resume and Stop rules, API and simulated services, the screen |
| `features/cards` | Models, API and simulated repositories, search/paging controller, the screen |
| `features/settings` | Language switch and persistence, alert simulator |
| `core/l10n` | Every enum value has text in both languages; language persistence |
| `core/widgets` | Design system components |

Use `pumpApp(tester, initialLocation: '/route')` to open a screen. Options:
`preferences` (e.g. `{'language_code': 'pt'}`), `linkService` and
`healthService` to swap the Bluetooth or server services.

## Roadmap

- [x] Splash with server check
- [x] Authentication (username/email + password, Google, remember me)
- [x] English UI with a language setting (English/Portuguese)
- [x] Machine linking over Bluetooth (simulated transport)
- [x] Alerts: banner and alerts screen
- [x] Automated tests
- [ ] Real Bluetooth transport (needs the machine's protocol)
- [x] Machine control: Start/Resume and Stop
- [ ] Machine progress and a Pause command
- [x] Cards in folders (search and list from the server)
- [ ] CSV report
- [ ] Sorting rules
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
