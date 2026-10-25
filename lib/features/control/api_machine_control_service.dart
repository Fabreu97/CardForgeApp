import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/api/api_contract.dart';
import '../../core/config/app_config.dart';
import '../auth/auth_service.dart';
import 'control_models.dart';
import 'machine_control_service.dart';

/// Real server. The routes, field names and status codes come from
/// `lib/core/api/api_contract.dart` (by default `GET /machines/{id}/status`,
/// `POST /machines/{id}/start` and `POST /machines/{id}/stop`, each answering
/// `{"state": "idle" | "running" | "stopped"}`).
class ApiMachineControlService implements MachineControlService {
  ApiMachineControlService({
    http.Client? client,
    Future<String?> Function()? tokenProvider,
    String? baseUrl,
  })  : _client = client ?? http.Client(),
        _tokenProvider = tokenProvider ?? AuthService.instance.accessToken,
        _baseUrl = baseUrl ?? AppConfig.apiBaseUrl;

  final http.Client _client;
  final Future<String?> Function() _tokenProvider;
  final String _baseUrl;

  @override
  Future<MachineRunState> status(String machineId) =>
      _call('GET', machineId, ApiRoutes.machineStatus);

  @override
  Future<MachineRunState> start(String machineId) =>
      _call('POST', machineId, ApiRoutes.machineStart);

  @override
  Future<MachineRunState> stop(String machineId) =>
      _call('POST', machineId, ApiRoutes.machineStop);

  Future<MachineRunState> _call(
    String method,
    String machineId,
    String route,
  ) async {
    final token = await _tokenProvider();
    final uri = Uri.parse('$_baseUrl${ApiRoutes.path(route, id: machineId)}');
    final headers = {
      'Accept': 'application/json',
      if (token != null) ApiHeaders.authorization: ApiHeaders.bearer(token),
    };

    final http.Response res;
    try {
      final request = method == 'GET'
          ? _client.get(uri, headers: headers)
          : _client.post(uri, headers: headers);
      res = await request.timeout(AppConfig.requestTimeout);
    } on Exception {
      throw const MachineControlException(
          MachineControlFailure.serverUnreachable);
    }

    if (res.statusCode == ApiStatus.unauthorized) {
      throw const MachineControlException(MachineControlFailure.unauthorized);
    }
    if (res.statusCode == ApiStatus.machineOffline) {
      throw const MachineControlException(MachineControlFailure.machineOffline);
    }
    if (res.statusCode != ApiStatus.ok) {
      throw const MachineControlException(MachineControlFailure.serverError);
    }

    try {
      final body =
          jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      final state = parseRunState(body[ApiFields.machineState]);
      if (state == null) throw const FormatException('unknown state');
      return state;
    } catch (_) {
      throw const MachineControlException(MachineControlFailure.serverError);
    }
  }
}
