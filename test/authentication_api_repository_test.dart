import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shiftly/features/auth/data/authentication_api_repository.dart';

class _SuccessAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async => ResponseBody.fromString(
    jsonEncode({'id': 'profile'}),
    201,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );

  @override
  void close({bool force = false}) {}
}

Future<Map<String, Object?>> _bootstrap({
  required String fullName,
  String? phone,
}) async {
  Object? capturedBody;
  final dio = Dio(BaseOptions(baseUrl: 'https://api.example.com/api/v1'))
    ..httpClientAdapter = _SuccessAdapter()
    ..interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          capturedBody = options.data;
          handler.next(options);
        },
      ),
    );
  await AuthenticationApiRepository(dio)
      .bootstrapProfile(fullName: fullName, phone: phone);
  return Map<String, Object?>.from(capturedBody! as Map);
}

void main() {
  test('empty phone is omitted from bootstrap JSON', () async {
    final body = await _bootstrap(fullName: 'Hazem', phone: '');
    expect(body, {'fullName': 'Hazem'});
    expect(body.containsKey('phone'), isFalse);
  });

  test('whitespace-only phone is omitted from bootstrap JSON', () async {
    final body = await _bootstrap(fullName: 'Hazem', phone: '   ');
    expect(body, {'fullName': 'Hazem'});
    expect(body.containsKey('phone'), isFalse);
  });

  test('phone and full name are trimmed before bootstrap', () async {
    final body = await _bootstrap(
      fullName: '  Hazem Mohammed  ',
      phone: '  +201234567890  ',
    );
    expect(body, {'fullName': 'Hazem Mohammed', 'phone': '+201234567890'});
    expect(body.keys, unorderedEquals(['fullName', 'phone']));
  });

  test('null phone is omitted from bootstrap JSON', () async {
    final body = await _bootstrap(fullName: '  Hazem  ');
    expect(body, {'fullName': 'Hazem'});
  });
}
