import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'machine_models.dart';

/// Remembers which machine is linked to this account on this phone.
class MachineStore extends ChangeNotifier {
  MachineStore(this._prefs) {
    final id = _prefs.getString(_idKey);
    final name = _prefs.getString(_nameKey);
    if (id != null && name != null) {
      _machine = LinkedMachine(id: id, name: name);
    }
  }

  static const String _idKey = 'machine_id';
  static const String _nameKey = 'machine_name';

  final SharedPreferences _prefs;
  LinkedMachine? _machine;

  LinkedMachine? get machine => _machine;

  Future<void> save(LinkedMachine machine) async {
    _machine = machine;
    notifyListeners();
    await _prefs.setString(_idKey, machine.id);
    await _prefs.setString(_nameKey, machine.name);
  }

  Future<void> clear() async {
    _machine = null;
    notifyListeners();
    await _prefs.remove(_idKey);
    await _prefs.remove(_nameKey);
  }
}
