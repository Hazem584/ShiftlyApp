import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shiftly/core/error/api_exception.dart';
import 'package:shiftly/features/notifications/data/api_notification_repository.dart';
import 'package:shiftly/features/notifications/data/notification_repository.dart';

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

ResponseBody _json(Object value, {int status = 200}) => ResponseBody.fromString(
  jsonEncode(value),
  status,
  headers: {
    Headers.contentTypeHeader: [Headers.jsonContentType],
  },
);

Map<String, Object?> _record({
  String type = 'SHIFT_ASSIGNED',
  Object? data = const {'shiftId': '5b6d92e6-7054-413f-ab26-bff810f2ff61'},
  String? readAt,
  String? workspaceId = 'c551356a-e456-4a3e-a49a-9dd0caa7e790',
}) => {
  'id': 'a5e624e8-ee45-4417-a932-5b48ad019656',
  'workspaceId': workspaceId,
  'type': type,
  'title': 'New shift assigned',
  'message': 'A new shift has been assigned to you.',
  'data': data,
  'readAt': readAt,
  'createdAt': '2026-09-28T08:00:00.000Z',
  'updatedAt': '2026-09-28T08:00:00.000Z',
};

({Dio dio, _Adapter adapter}) _client(
  FutureOr<ResponseBody> Function(RequestOptions options) handler,
) {
  final adapter = _Adapter(handler);
  final dio = Dio(BaseOptions(baseUrl: 'https://api.example.com/api/v1'))
    ..interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, next) {
          options.headers['Authorization'] = 'Bearer test-token';
          next.next(options);
        },
      ),
    )
    ..httpClientAdapter = adapter;
  return (dio: dio, adapter: adapter);
}

void main() {
  test(
    'uses exact list, count, mark, mark-all, and delete contracts',
    () async {
      final client = _client((options) {
        if (options.uri.path.endsWith('/unread-count')) {
          return _json({'count': 4});
        }
        if (options.uri.path.endsWith('/read-all')) {
          return _json({'updatedCount': 3});
        }
        if (options.method == 'DELETE') return _json({'deleted': true});
        if (options.uri.path.endsWith('/read')) {
          return _json(_record(readAt: '2026-09-28T09:00:00.000Z'));
        }
        return _json({
          'data': [_record()],
          'pagination': {'page': 2, 'limit': 10, 'total': 11, 'totalPages': 2},
        });
      });
      final repository = ApiNotificationRepository(client.dio);
      final page = await repository.list(
        'c551356a-e456-4a3e-a49a-9dd0caa7e790',
        const NotificationQuery(
          page: 2,
          limit: 10,
          unread: true,
          type: NotificationType.shiftAssigned,
        ),
      );
      expect(await repository.unreadCount(), 4);
      final read = await repository.markRead(
        'a5e624e8-ee45-4417-a932-5b48ad019656',
      );
      expect(
        await repository.markAllRead('c551356a-e456-4a3e-a49a-9dd0caa7e790'),
        3,
      );
      expect(
        await repository.delete('a5e624e8-ee45-4417-a932-5b48ad019656'),
        isTrue,
      );

      expect(client.adapter.requests[0].method, 'GET');
      expect(client.adapter.requests[0].uri.path, '/api/v1/notifications');
      expect(client.adapter.requests[0].queryParameters, {
        'page': 2,
        'limit': 10,
        'unread': true,
        'type': 'SHIFT_ASSIGNED',
        'workspaceId': 'c551356a-e456-4a3e-a49a-9dd0caa7e790',
      });
      expect(
        client.adapter.requests[0].headers['Authorization'],
        'Bearer test-token',
      );
      expect(
        client.adapter.requests[1].uri.path,
        '/api/v1/notifications/unread-count',
      );
      expect(
        client.adapter.requests[2].uri.path,
        '/api/v1/notifications/a5e624e8-ee45-4417-a932-5b48ad019656/read',
      );
      expect(
        client.adapter.requests[3].uri.path,
        '/api/v1/notifications/read-all',
      );
      expect(client.adapter.requests[3].data, {
        'workspaceId': 'c551356a-e456-4a3e-a49a-9dd0caa7e790',
      });
      expect(client.adapter.requests[4].method, 'DELETE');
      expect(page.pagination.total, 11);
      expect(page.data.single.createdAt.isUtc, isTrue);
      expect(read.readAt?.isUtc, isTrue);
    },
  );

  test('parses nullable data and unknown notification types safely', () async {
    final client = _client(
      (_) => _json({
        'data': [_record(type: 'FUTURE_EVENT', data: null, workspaceId: null)],
        'pagination': {'page': 1, 'limit': 20, 'total': 1, 'totalPages': 1},
      }),
    );
    final page = await ApiNotificationRepository(
      client.dio,
    ).list('c551356a-e456-4a3e-a49a-9dd0caa7e790', const NotificationQuery());
    expect(page.data.single.type, NotificationType.unknown);
    expect(page.data.single.workspaceId, isNull);
    expect(page.data.single.data, isNull);
    expect(page.data.single.readAt, isNull);
  });

  test('maps every confirmed backend notification type', () {
    const values = {
      'ATTENDANCE_CLOCKED_IN': NotificationType.attendanceClockedIn,
      'ATTENDANCE_CLOCKED_OUT': NotificationType.attendanceClockedOut,
      'LEAVE_REQUEST_CREATED': NotificationType.leaveRequestCreated,
      'LEAVE_REQUEST_APPROVED': NotificationType.leaveRequestApproved,
      'LEAVE_REQUEST_REJECTED': NotificationType.leaveRequestRejected,
      'SHIFT_ASSIGNED': NotificationType.shiftAssigned,
      'SHIFT_UPDATED': NotificationType.shiftUpdated,
      'SHIFT_CANCELLED': NotificationType.shiftCancelled,
    };
    for (final entry in values.entries) {
      expect(NotificationType.parse(entry.key), entry.value);
      expect(entry.value.apiValue, entry.key);
    }
  });

  test('malformed success and typed backend errors are safe', () async {
    final malformed = _client((_) => _json({'count': 'four'}));
    await expectLater(
      ApiNotificationRepository(malformed.dio).unreadCount(),
      throwsA(isA<ApiException>()),
    );
    final malformedData = _client(
      (_) => _json({
        'data': [_record(data: 'not-an-object')],
        'pagination': {'page': 1, 'limit': 20, 'total': 1, 'totalPages': 1},
      }),
    );
    await expectLater(
      ApiNotificationRepository(
        malformedData.dio,
      ).list('c551356a-e456-4a3e-a49a-9dd0caa7e790', const NotificationQuery()),
      throwsA(isA<ApiException>()),
    );
    final backend = _client(
      (_) => _json({
        'statusCode': 404,
        'code': 'NOTIFICATION_NOT_FOUND',
        'message': 'private detail',
        'requestId': 'request-id',
      }, status: 404),
    );
    await expectLater(
      ApiNotificationRepository(backend.dio)
          .delete('a5e624e8-ee45-4417-a932-5b48ad019656'),
      throwsA(
        isA<ApiException>()
            .having((error) => error.code, 'code', 'NOTIFICATION_NOT_FOUND')
            .having((error) => error.requestId, 'requestId', 'request-id')
            .having(
              (error) => error.message,
              'message',
              'That notification is no longer available.',
            ),
      ),
    );
  });
}
