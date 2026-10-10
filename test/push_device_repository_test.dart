import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shiftly/core/error/api_exception.dart';
import 'package:shiftly/features/notifications/data/api_push_device_repository.dart';
import 'package:shiftly/features/notifications/data/preferences_push_store.dart';
import 'package:shiftly/features/notifications/domain/entities/notification_type.dart';

class _Adapter implements HttpClientAdapter {
  _Adapter(this.handler);
  final ResponseBody Function(RequestOptions) handler;
  final requests = <RequestOptions>[];
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _json(Object value, {int status = 200}) => ResponseBody.fromString(
  jsonEncode(value),
  status,
  headers: {
    Headers.contentTypeHeader: [Headers.jsonContentType],
  },
);

void main() {
  test(
    'device registration and idempotent revocation use the agreed API contract',
    () async {
      final adapter = _Adapter(
        (options) => _json(
          options.method == 'PUT' ? {'registered': true} : {'deleted': true},
        ),
      );
      final dio = Dio(
        BaseOptions(baseUrl: 'https://api.example.invalid/api/v1'),
      )..httpClientAdapter = adapter;
      addTearDown(dio.close);
      final repository = ApiPushDeviceRepository(dio);
      await repository.register(
        installationId: 'installation',
        token: 'private-token',
        platform: 'ANDROID',
      );
      await repository.unregister('installation');
      expect(adapter.requests.first.path, '/notifications/devices');
      expect(adapter.requests.first.data, {
        'installationId': 'installation',
        'token': 'private-token',
        'platform': 'ANDROID',
      });
      expect(adapter.requests.last.method, 'DELETE');
      expect(adapter.requests.last.path, '/notifications/devices/installation');
    },
  );

  test(
    'invalid successful acknowledgement is never treated as registered',
    () async {
      final dio = Dio()
        ..httpClientAdapter = _Adapter((_) => _json({'registered': false}));
      addTearDown(dio.close);
      await expectLater(
        ApiPushDeviceRepository(dio).register(
          installationId: 'installation',
          token: 'private-token',
          platform: 'IOS',
        ),
        throwsA(isA<ApiException>()),
      );
    },
  );

  test('canonical push notification is fetched and decoded rather than trusting payload routes', () async {
    final adapter = _Adapter(
      (_) => _json({
        'id': 'notification',
        'workspaceId': 'workspace',
        'type': 'CHAT_MESSAGE',
        'title': 'New chat message',
        'message': 'You have a new chat message.',
        'data': {'groupId': 'group'},
        'readAt': null,
        'createdAt': '2026-10-10T08:00:00Z',
        'updatedAt': '2026-10-10T08:00:00Z',
      }),
    );
    final dio = Dio()..httpClientAdapter = adapter;
    addTearDown(dio.close);
    final record = await ApiPushDeviceRepository(dio)
        .getNotification('notification');
    expect(adapter.requests.single.path, '/notifications/notification');
    expect(record.type, NotificationType.chatMessage);
    expect(record.data!['groupId'], 'group');
  });

  test(
    'installation identity persists while consent remains account-specific',
    () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final store = PreferencesPushStore(prefs);
      final installation = await store.installationId();
      expect(installation, matches(RegExp(r'^[0-9a-f-]{36}$')));
      await store.setEnabled('first-user', true);
      final reopened = PreferencesPushStore(prefs);
      expect(await reopened.installationId(), installation);
      expect(await reopened.enabled('first-user'), isTrue);
      expect(await reopened.enabled('second-user'), isFalse);
      await reopened.setEnabled('first-user', false);
      expect(await store.enabled('first-user'), isFalse);
    },
  );
}
