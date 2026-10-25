import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../features/alerts/alerts_controller.dart';
import '../features/cards/card_repository.dart';
import '../features/cards/mock_card_repository.dart';
import '../features/control/api_machine_control_service.dart';
import '../features/control/machine_control_service.dart';
import '../features/control/mock_machine_control_service.dart';
import '../features/machine/machine_link_service.dart';
import '../features/machine/machine_store.dart';
import '../features/machine/mock_machine_link_service.dart';
import 'config/app_config.dart';
import 'l10n/locale_controller.dart';

/// Objects shared by the whole app (language, alerts, linked machine, Bluetooth).
class AppDependencies {
  AppDependencies({
    required this.locale,
    required this.alerts,
    required this.machineStore,
    required this.linkService,
    required this.cardRepository,
    required this.machineControl,
    GlobalKey<ScaffoldMessengerState>? messengerKey,
  }) : messengerKey = messengerKey ?? GlobalKey<ScaffoldMessengerState>();

  factory AppDependencies.create(
    SharedPreferences prefs, {
    MachineLinkService? linkService,
    CardRepository? cardRepository,
    MachineControlService? machineControl,
  }) {
    return AppDependencies(
      locale: LocaleController(prefs),
      alerts: AlertsController(),
      machineStore: MachineStore(prefs),
      linkService: linkService ??
          (AppConfig.useMockBluetooth
              ? MockMachineLinkService()
              : const UnavailableMachineLinkService()),
      cardRepository: cardRepository ??
          (AppConfig.useMockBackend
              ? MockCardRepository()
              : ApiCardRepository()),
      machineControl: machineControl ??
          (AppConfig.useMockBackend
              ? MockMachineControlService()
              : ApiMachineControlService()),
    );
  }

  final LocaleController locale;
  final AlertsController alerts;
  final MachineStore machineStore;
  final MachineLinkService linkService;
  final CardRepository cardRepository;
  final MachineControlService machineControl;

  /// Lets the app show alert banners from anywhere, on top of any screen.
  final GlobalKey<ScaffoldMessengerState> messengerKey;
}

/// Gives every screen access to [AppDependencies]:
/// `AppScope.of(context).alerts`.
class AppScope extends InheritedWidget {
  const AppScope({super.key, required this.deps, required super.child});

  final AppDependencies deps;

  /// Does not register a dependency, so it is safe to call in `initState`.
  /// Widgets that need updates listen to the specific controller instead.
  static AppDependencies of(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope not found above this widget.');
    return scope!.deps;
  }

  @override
  bool updateShouldNotify(AppScope oldWidget) => deps != oldWidget.deps;
}
