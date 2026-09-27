import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shiftly/core/error/api_exception.dart';
import 'package:shiftly/features/auth/data/models/current_user.dart';
import 'package:shiftly/features/profile/data/api_profile_repository.dart';
import 'package:shiftly/features/profile/data/profile_image_picker.dart';

class _Adapter implements HttpClientAdapter {
  _Adapter(this.handler);
  final FutureOr<ResponseBody> Function(RequestOptions options) handler;
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

ResponseBody _json(Object body, {int status = 200}) => ResponseBody.fromString(
  jsonEncode(body),
  status,
  headers: {
    Headers.contentTypeHeader: [Headers.jsonContentType],
  },
);

Map<String, Object?> _profile({String? avatarUrl}) => {
  'id': 'profile-id',
  'email': null,
  'fullName': null,
  'phone': null,
  'avatarUrl': avatarUrl,
  'createdAt': '2026-09-25T08:00:00.000Z',
  'updatedAt': '2026-09-25T09:00:00.000Z',
};

Map<String, Object?> _currentUser() => {
  ..._profile(),
  'memberships': [
    {
      'id': 'manager-membership-id',
      'role': 'MANAGER',
      'status': 'ACTIVE',
      'jobTitle': 'Operations Manager',
      'joinedAt': '2026-09-25T08:00:00.000Z',
      'workspace': {
        'id': 'workspace-id',
        'name': 'Shift Lab',
        'code': 'SHIFT',
        'timezone': 'Africa/Cairo',
      },
    },
  ],
};

WorkspaceMembership _membership() => WorkspaceMembership.fromJson(
  Map<String, Object?>.from(
    (_currentUser()['memberships']! as List).single as Map,
  ),
);

({ApiProfileRepository repository, _Adapter adapter}) _repository(
  FutureOr<ResponseBody> Function(RequestOptions options) handler,
) {
  final adapter = _Adapter(handler);
  final dio = Dio(BaseOptions(baseUrl: 'https://api.example.com/api/v1'))
    ..httpClientAdapter = adapter;
  return (repository: ApiProfileRepository(dio, _membership), adapter: adapter);
}

void main() {
  test('load uses GET /auth/me and supports nullable profile fields', () async {
    final client = _repository((_) => _json(_currentUser()));
    final profile = await client.repository.getProfile();
    expect(client.adapter.requests.single.method, 'GET');
    expect(client.adapter.requests.single.uri.path, '/api/v1/auth/me');
    expect(profile.fullName, isNull);
    expect(profile.email, isNull);
    expect(profile.phone, isNull);
    expect(profile.displayName, 'Shiftly user');
    expect(profile.displayEmail, 'Not provided');
    expect(profile.displayPhone, 'Not provided');
    expect(profile.avatarUrl, isNull);
    expect(profile.createdAt?.isUtc, isTrue);
  });

  test('update sends JSON null when phone is cleared', () async {
    final client = _repository((_) => _json(_profile()));

    final profile = await client.repository.updateProfile(
      fullName: '  Hazem  ',
      phone: null,
    );

    expect(client.adapter.requests.single.data, {
      'fullName': 'Hazem',
      'phone': null,
    });
    expect(profile.phone, isNull);
  });

  test('update trims and sends only fullName and phone', () async {
    final client = _repository(
      (_) => _json({..._profile(), 'fullName': 'Hazem'}),
    );
    await client.repository.updateProfile(
      fullName: '  Hazem  ',
      phone: '  +20123  ',
    );
    final request = client.adapter.requests.single;
    expect(request.method, 'PATCH');
    expect(request.uri.path, '/api/v1/profiles/me');
    expect(request.data, {'fullName': 'Hazem', 'phone': '+20123'});
    expect((request.data! as Map).containsKey('avatarUrl'), isFalse);
    expect((request.data! as Map).keys, unorderedEquals(['fullName', 'phone']));
  });

  test(
    'avatar upload uses exact multipart key and cloneable FormData',
    () async {
      FormData? body;
      final client = _repository((options) {
        body = options.data! as FormData;
        return _json({
          ..._profile(),
          'avatarUrl': 'https://cdn.example/avatar.png',
        });
      });
      await client.repository.uploadAvatar(
        ProfileImageSelection(
          fileName: 'avatar.png',
          bytes: Uint8List.fromList([
            0x89,
            0x50,
            0x4E,
            0x47,
            0x0D,
            0x0A,
            0x1A,
            0x0A,
          ]),
        ),
      );
      final request = client.adapter.requests.single;
      expect(request.method, 'POST');
      expect(request.uri.path, '/api/v1/profiles/me/avatar');
      expect(body!.files.single.key, 'avatar');
      expect(body!.clone().files.single.key, 'avatar');
    },
  );

  test('avatar delete uses DELETE and parses canonical null avatar', () async {
    final client = _repository((_) => _json(_profile()));
    final profile = await client.repository.deleteAvatar();
    expect(client.adapter.requests.single.method, 'DELETE');
    expect(
      client.adapter.requests.single.uri.path,
      '/api/v1/profiles/me/avatar',
    );
    expect(profile.avatarUrl, isNull);
  });

  test('malformed success becomes a safe typed failure', () async {
    final client = _repository((_) => _json({'id': 'missing-fields'}));
    await expectLater(
      client.repository.updateProfile(fullName: 'Hazem', phone: null),
      throwsA(
        isA<ApiException>().having(
          (error) => error.message,
          'safe message',
          isNot(contains('Invalid updatedAt')),
        ),
      ),
    );
  });

  test('backend code and requestId are preserved', () async {
    final client = _repository(
      (_) => _json({
        'statusCode': 429,
        'code': 'RATE_LIMIT_EXCEEDED',
        'message': 'Too many requests',
        'requestId': 'request-id',
        'path': '/api/v1/profiles/me',
      }, status: 429),
    );
    await expectLater(
      client.repository.updateProfile(fullName: 'Hazem', phone: null),
      throwsA(
        isA<ApiException>()
            .having((error) => error.code, 'code', 'RATE_LIMIT_EXCEEDED')
            .having((error) => error.requestId, 'requestId', 'request-id'),
      ),
    );
  });
}
