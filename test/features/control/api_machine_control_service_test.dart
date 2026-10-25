import 'dart:convert';

import 'package:cardforge/features/control/api_machine_control_service.dart';
import 'package:cardforge/features/control/control_models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const _id = 'B8:27:EB:00:A1:B2';

http.Response _state(String state, [int status = 200]) =>
    http.Response.bytes(utf8.encode(jsonEncode({'state': state})), status);

ApiMachineControlService _service(MockClient client, {String? token = 'abc'}) =>
    ApiMachineControlService(
      client: client,
      tokenProvider: () async => token,
      baseUrl: 'https://api.test',
    );

void main() {
  test('status asks GET /machines/{id}/status with the bearer token', () async {
    late http.Request seen;
    final service = _service(MockClient((request) async {
      seen = request;
      return _state('running');
    }));

    final state = await service.status(_id);

    expect(state, MachineRunState.running);
    expect(seen.method, 'GET');
    expect(seen.url.pathSegments, ['machines', _id, 'status']);
    expect(seen.headers['Authorization'], 'Bearer abc');
  });

  test('start and stop are POSTs to their own routes', () async {
    final seen = <http.Request>[];
    final service = _service(MockClient((request) async {
      seen.add(request);
      return _state(request.url.pathSegments.last == 'start'
          ? 'running'
          : 'stopped');
    }));

    expect(await service.start(_id), MachineRunState.running);
    expect(await service.stop(_id), MachineRunState.stopped);

    expect(seen.map((r) => r.method), ['POST', 'POST']);
    expect(seen.map((r) => r.url.pathSegments.last), ['start', 'stop']);
  });

  test('the machine id is encoded in the path', () async {
    late http.Request seen;
    final service = _service(MockClient((request) async {
      seen = request;
      return _state('idle');
    }));

    await service.status(_id);

    expect(seen.url.path, contains('%3A'));
  });

  test('sends no Authorization header when there is no token', () async {
    late http.Request seen;
    final service = _service(
      MockClient((request) async {
        seen = request;
        return _state('idle');
      }),
      token: null,
    );

    await service.status(_id);

    expect(seen.headers.containsKey('Authorization'), isFalse);
  });

  Future<MachineControlFailure> failureOf(MockClient client) async {
    try {
      await _service(client).start(_id);
    } on MachineControlException catch (e) {
      return e.failure;
    }
    fail('expected a MachineControlException');
  }

  test('401 means the session expired', () async {
    expect(await failureOf(MockClient((_) async => _state('idle', 401))),
        MachineControlFailure.unauthorized);
  });

  test('409 means the machine is offline', () async {
    expect(await failureOf(MockClient((_) async => _state('idle', 409))),
        MachineControlFailure.machineOffline);
  });

  test('other statuses and unreadable answers are server errors', () async {
    expect(await failureOf(MockClient((_) async => _state('idle', 500))),
        MachineControlFailure.serverError);
    expect(await failureOf(MockClient((_) async => _state('flying'))),
        MachineControlFailure.serverError);
    expect(
        await failureOf(
            MockClient((_) async => http.Response('not json at all', 200))),
        MachineControlFailure.serverError);
  });

  test('no connection means the server is unreachable', () async {
    expect(
      await failureOf(MockClient((_) async => throw http.ClientException('x'))),
      MachineControlFailure.serverUnreachable,
    );
  });
}
