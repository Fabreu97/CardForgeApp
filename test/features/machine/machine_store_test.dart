import 'package:cardforge/features/machine/machine_models.dart';
import 'package:cardforge/features/machine/machine_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<SharedPreferences> prefsWith(Map<String, Object> values) async {
    SharedPreferences.setMockInitialValues(values);
    return SharedPreferences.getInstance();
  }

  test('starts without a machine', () async {
    final store = MachineStore(await prefsWith({}));

    expect(store.machine, isNull);
  });

  test('save remembers the machine and notifies listeners', () async {
    final prefs = await prefsWith({});
    final store = MachineStore(prefs);
    var notified = 0;
    store.addListener(() => notified++);

    await store.save(const LinkedMachine(id: 'AA', name: 'CardForge-A1B2'));

    expect(store.machine?.name, 'CardForge-A1B2');
    expect(notified, 1);
    // A new store (a new app launch) reads it back.
    expect(MachineStore(prefs).machine?.id, 'AA');
  });

  test('clear forgets the machine', () async {
    final prefs = await prefsWith({'machine_id': 'AA', 'machine_name': 'X'});
    final store = MachineStore(prefs);
    expect(store.machine, isNotNull);

    await store.clear();

    expect(store.machine, isNull);
    expect(MachineStore(prefs).machine, isNull);
  });
}
