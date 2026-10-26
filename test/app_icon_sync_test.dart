import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shiftly/core/app_icons/app_icon_sync.dart';

class IconAdapter implements HttpClientAdapter {
  Object selection;
  IconAdapter(this.selection);
  @override
  Future<ResponseBody> fetch(
    RequestOptions o,
    Stream<Uint8List>? s,
    Future<void>? c,
  ) async => ResponseBody.fromString(
    jsonEncode(selection),
    200,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );
  @override
  void close({bool force = false}) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('shiftly/app_icons');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  tearDown(() => messenger.setMockMethodCallHandler(channel, null));
  for (final key in ['default', 'icon_${'a' * 64}', 'icon_${'b' * 64}']) {
    test('applies only bundled and matching icon selection $key', () async {
      final calls = <String>[];
      messenger.setMockMethodCallHandler(channel, (c) async {
        if (c.method == 'capabilities') {
          return {
            'supported': true,
            'icons': {'default': 'default', 'icon_${'a' * 64}': 'a' * 64},
            'current': 'other',
          };
        }
        calls.add(c.arguments['key'] as String);
        return true;
      });
      final dio = Dio()
        ..httpClientAdapter = IconAdapter({
          'key': key,
          'sha256': key == 'default' ? null : key.substring(5),
          'revision': 1,
        });
      final sync = AppIconSync(dio, enabled: true);
      await sync.synchronize();
      expect(calls, key.contains('b') ? <String>[] : [key]);
      sync.dispose();
    });
  }
  test(
    'a mismatched digest or fetch failure leaves the launcher unchanged',
    () async {
      var changes = 0;
      messenger.setMockMethodCallHandler(channel, (c) async {
        if (c.method == 'capabilities') {
          return {
            'supported': true,
            'icons': {'default': 'default', 'icon_${'a' * 64}': 'a' * 64},
            'current': 'default',
          };
        }
        changes++;
        return true;
      });
      final dio = Dio()
        ..httpClientAdapter = IconAdapter({
          'key': 'icon_${'a' * 64}',
          'sha256': 'b' * 64,
        });
      final sync = AppIconSync(dio, enabled: true);
      await sync.synchronize();
      expect(changes, 0);
      sync.dispose();
    },
  );
  test('unsupported platforms skip network and native operations', () async {
    final dio = Dio();
    final sync = AppIconSync(dio, enabled: false);
    await sync.synchronize();
    sync.dispose();
  });
}
