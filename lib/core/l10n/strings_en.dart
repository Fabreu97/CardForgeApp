import '../../features/alerts/machine_alert.dart';
import '../../features/auth/auth_service.dart';
import '../../features/cards/card_models.dart';
import '../../features/machine/machine_models.dart';
import 'app_strings.dart';

class EnStrings extends AppStrings {
  const EnStrings();

  // Common
  @override
  String get tryAgain => 'Try again';
  @override
  String get back => 'Back';
  @override
  String get view => 'View';
  @override
  String get done => 'Done';
  @override
  String get close => 'Close';
  @override
  String comingSoon(String feature) => '$feature is coming soon.';

  // Splash
  @override
  String get appTagline => 'Organize your Magic cards';
  @override
  String get splashConnecting => 'Connecting to server…';
  @override
  String get splashCheckingSession => 'Checking session…';
  @override
  String get serverUnreachableTitle => 'Could not reach the server';
  @override
  String get serverUnreachableHint =>
      'Check your internet connection and try again.';

  // Login
  @override
  String get loginSubtitle => 'Sign in to manage your sorter';
  @override
  String get usernameOrEmail => 'Username or email';
  @override
  String get password => 'Password';
  @override
  String get showPassword => 'Show password';
  @override
  String get hidePassword => 'Hide password';
  @override
  String get rememberMe => 'Remember me';
  @override
  String get signIn => 'Sign in';
  @override
  String get forgotPassword => 'Forgot password?';
  @override
  String get orDivider => 'or';
  @override
  String get continueWithGoogle => 'Continue with Google';
  @override
  String get newHere => 'New here?';
  @override
  String get createAccount => 'Create account';
  @override
  String get passwordRecoverySoon => 'Password recovery is coming soon.';
  @override
  String get signUpSoon => 'Sign-up is coming soon.';
  @override
  String get usernameRequired => 'Enter your username or email';
  @override
  String get invalidEmail => 'Invalid email';
  @override
  String get passwordRequired => 'Enter your password';
  @override
  String get passwordTooShort => 'Password must have at least 6 characters';
  @override
  String authError(AuthFailure failure) => switch (failure) {
        AuthFailure.invalidCredentials => 'Invalid username or password.',
        AuthFailure.serverUnreachable =>
          'Cannot reach the server. Please try again.',
        AuthFailure.serverError => 'Server error. Please try again.',
        AuthFailure.googleCancelled => 'Google sign-in was cancelled.',
        AuthFailure.googleTokenMissing =>
          'Could not get a token from Google.',
      };

  // Home and menu
  @override
  String get noMachineTitle => 'No machine linked';
  @override
  String get noMachineBody =>
      'Link your sorter to follow and control card sorting.';
  @override
  String get machineLinkedBody => 'Linked to your account';
  @override
  String get menuMachineControl => 'Machine control';
  @override
  String get menuCardsInFolders => 'Cards in folders';
  @override
  String get menuCsvReport => 'CSV report';
  @override
  String get menuSortingRules => 'Sorting rules';
  @override
  String get linkMachine => 'Link machine';
  @override
  String get alerts => 'Alerts';
  @override
  String get settings => 'Settings';
  @override
  String get signOut => 'Sign out';

  // Link machine
  @override
  String get selectMachine => 'Select your machine';
  @override
  String get scanningForMachines => 'Searching for CardForge machines nearby…';
  @override
  String get scanAgain => 'Scan again';
  @override
  String get noMachinesFound => 'No machines found';
  @override
  String get noMachinesHint =>
      'Make sure the machine is powered on and nearby, then scan again.';
  @override
  String get scanFailedTitle => 'Bluetooth search failed';
  @override
  String get enterMachinePassword => 'Machine password';
  @override
  String machinePasswordHint(String machineName) =>
      'Enter the password of $machineName to allow linking.';
  @override
  String get machinePassword => 'Machine password';
  @override
  String get machinePasswordRequired => 'Enter the machine password';
  @override
  String get verifyPassword => 'Verify password';
  @override
  String get chooseAnotherMachine => 'Choose another machine';
  @override
  String get wifiQuestionTitle => 'Send Wi-Fi details?';
  @override
  String get wifiQuestionBody =>
      'Your machine needs a Wi-Fi connection to talk to the server. '
      'Send your network name and password now?';
  @override
  String get sendWifi => 'Yes, send Wi-Fi';
  @override
  String get skipWifi => 'Skip for now';
  @override
  String get wifiFormTitle => 'Wi-Fi details';
  @override
  String get networkName => 'Network name (SSID)';
  @override
  String get networkNameRequired => 'Enter the network name';
  @override
  String get wifiPassword => 'Wi-Fi password';
  @override
  String get wifiPasswordHint => 'Leave empty for open networks';
  @override
  String get wifiTip =>
      'Tip: some Raspberry Pi 3 models only support 2.4 GHz networks.';
  @override
  String get sendAndLink => 'Send and link';
  @override
  String get linkingTitle => 'Linking your machine';
  @override
  String get linkingHint =>
      'The machine will confirm when everything is ready. '
      'This can take up to a minute.';
  @override
  String linkStep(LinkStep step) => switch (step) {
        LinkStep.sendingWifi => 'Sending Wi-Fi details…',
        LinkStep.waitingForWifi =>
          'Waiting for the machine to connect to Wi-Fi…',
        LinkStep.linkingAccount => 'Linking machine to your account…',
        LinkStep.done => 'Done',
      };
  @override
  String get linkSuccessTitle => 'Machine linked!';
  @override
  String linkSuccessBody(String machineName) =>
      '$machineName is ready. Start a sorting run from the machine control screen.';
  @override
  String get linkFailureTitle => 'Could not link the machine';
  @override
  String linkFailure(MachineLinkFailure failure) => switch (failure) {
        MachineLinkFailure.bluetoothUnavailable =>
          'Bluetooth is unavailable. Turn it on and try again.',
        MachineLinkFailure.wrongPassword => 'Wrong machine password.',
        MachineLinkFailure.connectionLost =>
          'Lost the connection to the machine.',
        MachineLinkFailure.wifiFailed =>
          'The machine could not connect to that Wi-Fi network. '
              'Check the name and password.',
        MachineLinkFailure.accountLinkFailed =>
          'The machine connected, but linking it to your account failed.',
        MachineLinkFailure.timeout =>
          'The machine did not confirm in time. Please try again.',
        MachineLinkFailure.notImplemented =>
          'Bluetooth linking is not available in this build yet.',
        MachineLinkFailure.unknown => 'Something went wrong. Please try again.',
      };

  // Cards in folders
  @override
  String get searchCardsHint => 'Search a card by name';
  @override
  String get clearSearch => 'Clear search';
  @override
  String get allCardsHeader => 'Cards in your folders';
  @override
  String resultsFor(String query) => 'Results for “$query”';
  @override
  String cardsCount(int count) => count == 1 ? '1 card' : '$count cards';
  @override
  String copiesCount(int quantity) =>
      quantity == 1 ? '1 copy' : '$quantity copies';
  @override
  String folderLabel(int folder) => 'Folder $folder';
  @override
  String get cardsEmptyTitle => 'No cards in the folders yet';
  @override
  String get cardsEmptyHint => 'Cards show up here after a sorting run.';
  @override
  String get noCardsFoundTitle => 'No cards found';
  @override
  String get noCardsFoundHint => 'Check the spelling or try another name.';
  @override
  String get cardsLoadFailedTitle => 'Could not load the cards';
  @override
  String cardsFailure(CardsFailure failure) => switch (failure) {
        CardsFailure.unauthorized =>
          'Your session expired. Please sign in again.',
        CardsFailure.serverUnreachable =>
          'Cannot reach the server. Check your connection and try again.',
        CardsFailure.serverError =>
          'The server had a problem. Please try again.',
      };
  @override
  String get signInAgain => 'Sign in again';

  // Settings
  @override
  String get languageSection => 'Language';
  @override
  String get developerTools => 'Developer tools';
  @override
  String get simulateAlerts => 'Simulate alerts';

  // Alerts
  @override
  String get noAlerts => 'No alerts yet';
  @override
  String get noAlertsHint => 'Machine events will show up here.';
  @override
  String get markAllRead => 'Mark all as read';
  @override
  String get clearAll => 'Clear all';
  @override
  String get yourMachine => 'Your machine';
  @override
  String alertTitle(AlertType type) => switch (type) {
        AlertType.wifiConnected => 'Machine connected to Wi-Fi',
        AlertType.wifiDisconnected => 'Machine lost Wi-Fi',
        AlertType.batchFinished => 'Sorting finished',
        AlertType.jamDetected => 'Card jam detected',
        AlertType.doubleFeed => 'Double feed detected',
        AlertType.connectionLost => 'Connection lost',
        AlertType.machineLinked => 'Machine linked',
      };
  @override
  String alertMessage(MachineAlert alert) {
    final name = alert.machineName ?? yourMachine;
    return switch (alert.type) {
      AlertType.wifiConnected => '$name is online.',
      AlertType.wifiDisconnected => '$name is offline. Check your Wi-Fi network.',
      AlertType.batchFinished =>
        '$name processed ${alert.cardCount ?? 0} cards.',
      AlertType.jamDetected => '$name stopped. Clear the jam and resume.',
      AlertType.doubleFeed => '$name picked up two cards at once.',
      AlertType.connectionLost => 'Lost contact with $name. Sorting is paused.',
      AlertType.machineLinked => '$name is now linked to your account.',
    };
  }
}
