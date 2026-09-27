import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shiftly/core/error/api_exception.dart';
import 'package:shiftly/features/attendance/data/api_leave_request_repository.dart';
import 'package:shiftly/features/attendance/data/leave_request_repository.dart';

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
  String status = 'PENDING',
  String type = 'ANNUAL_LEAVE',
}) => {
  'id': 'leave-id',
  'workspaceId': 'workspace-id',
  'employeeMembershipId': 'employee-id',
  'type': type,
  'status': status,
  'startsAt': '2026-10-01T00:00:00.000Z',
  'endsAt': '2026-10-01T23:59:00.000Z',
  'reason': 'Family event',
  'reviewedByMembershipId': null,
  'reviewedAt': null,
  'rejectionReason': null,
  'cancelledAt': null,
  'createdAt': '2026-09-27T10:00:00.000Z',
  'updatedAt': '2026-09-27T10:00:00.000Z',
  'employee': {
    'id': 'employee-id',
    'profileId': 'profile-id',
    'role': 'EMPLOYEE',
    'status': 'ACTIVE',
    'fullName': 'Mariam Hassan',
    'email': null,
    'phone': null,
    'avatarUrl': null,
    'jobTitle': null,
    'joinedAt': null,
  },
};

({Dio dio, _Adapter adapter}) _client(
  FutureOr<ResponseBody> Function(RequestOptions options) handler,
) {
  final adapter = _Adapter(handler);
  final dio = Dio(BaseOptions(baseUrl: 'https://api.example.com/api/v1'))
    ..httpClientAdapter = adapter;
  return (dio: dio, adapter: adapter);
}

void main() {
  test(
    'uses all employee and manager routes with exact payloads and queries',
    () async {
      final client = _client((options) {
        final list =
            options.method == 'GET' &&
            (options.uri.path.endsWith('/me') ||
                options.uri.path.endsWith('/leave-requests'));
        final status = options.uri.path.endsWith('/cancel')
            ? 'CANCELLED'
            : options.uri.path.endsWith('/review')
            ? 'REJECTED'
            : 'PENDING';
        return _json(
          list
              ? {
                  'data': [_record()],
                  'pagination': {
                    'page': 1,
                    'limit': 20,
                    'total': 1,
                    'totalPages': 1,
                  },
                }
              : _record(status: status),
          status: options.method == 'POST' ? 201 : 200,
        );
      });
      final repository = ApiLeaveRequestRepository(client.dio);
      await repository.create(
        'workspace-id',
        CreateLeaveRequestInput(
          type: LeaveRequestType.sickLeave,
          startsAt: DateTime.parse('2026-10-01T02:00:00+02:00'),
          endsAt: DateTime.parse('2026-10-02T01:59:00+02:00'),
          reason: ' Doctor ',
        ),
      );
      await repository.listMine(
        'workspace-id',
        const LeaveRequestQuery(page: 2, status: LeaveRequestStatus.pending),
      );
      await repository.getMine('leave-id');
      await repository.cancelMine('leave-id');
      await repository.listWorkspace(
        'workspace-id',
        const LeaveRequestQuery(
          type: LeaveRequestType.annualLeave,
          employeeMembershipId: 'employee-id',
          search: ' Mariam ',
        ),
      );
      await repository.getWorkspace('workspace-id', 'leave-id');
      final reviewed = await repository.review(
        'workspace-id',
        'leave-id',
        LeaveReviewDecision.rejected,
        rejectionReason: ' No coverage ',
      );

      expect(client.adapter.requests[0].uri.path, '/api/v1/leave-requests');
      expect(client.adapter.requests[0].data, {
        'workspaceId': 'workspace-id',
        'type': 'SICK_LEAVE',
        'startsAt': '2026-10-01T00:00:00.000Z',
        'endsAt': '2026-10-01T23:59:00.000Z',
        'reason': 'Doctor',
      });
      expect(client.adapter.requests[1].uri.path, '/api/v1/leave-requests/me');
      expect(client.adapter.requests[1].queryParameters, {
        'page': 2,
        'limit': 20,
        'status': 'PENDING',
        'workspaceId': 'workspace-id',
      });
      expect(
        client.adapter.requests[2].uri.path,
        '/api/v1/leave-requests/me/leave-id',
      );
      expect(
        client.adapter.requests[3].uri.path,
        '/api/v1/leave-requests/me/leave-id/cancel',
      );
      expect(client.adapter.requests[4].queryParameters, {
        'page': 1,
        'limit': 20,
        'type': 'ANNUAL_LEAVE',
        'employeeMembershipId': 'employee-id',
        'search': 'Mariam',
      });
      expect(
        client.adapter.requests[5].uri.path,
        '/api/v1/workspaces/workspace-id/leave-requests/leave-id',
      );
      expect(client.adapter.requests[6].data, {
        'decision': 'REJECTED',
        'rejectionReason': 'No coverage',
      });
      expect(reviewed.status, LeaveRequestStatus.rejected);
      expect(reviewed.rejectionReason, isNull);
    },
  );

  test('unknown enum values and nullable fields parse safely', () async {
    final client = _client(
      (_) => _json(_record(status: 'FUTURE_STATUS', type: 'FUTURE_TYPE')),
    );
    final record = await ApiLeaveRequestRepository(client.dio)
        .getMine('leave-id');
    expect(record.status, LeaveRequestStatus.unknown);
    expect(record.type, LeaveRequestType.unknown);
    expect(record.employee.email, isNull);
  });

  test(
    'malformed success and backend errors become safe ApiExceptions',
    () async {
      final malformed = _client((_) => _json({'id': 'leave-id'}));
      await expectLater(
        ApiLeaveRequestRepository(malformed.dio).getMine('leave-id'),
        throwsA(isA<ApiException>()),
      );
      final backend = _client(
        (_) => _json({
          'statusCode': 409,
          'code': 'LEAVE_REQUEST_OVERLAP',
          'message': 'private',
          'requestId': 'request-id',
        }, status: 409),
      );
      await expectLater(
        ApiLeaveRequestRepository(backend.dio).cancelMine('leave-id'),
        throwsA(
          isA<ApiException>()
              .having((error) => error.code, 'code', 'LEAVE_REQUEST_OVERLAP')
              .having((error) => error.requestId, 'requestId', 'request-id')
              .having(
                (error) => error.message,
                'message',
                contains('overlaps'),
              ),
        ),
      );
    },
  );
}
