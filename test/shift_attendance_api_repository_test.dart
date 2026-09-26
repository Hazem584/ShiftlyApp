import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shiftly/core/error/api_exception.dart';
import 'package:shiftly/features/attendance/data/api_attendance_repository.dart';
import 'package:shiftly/features/attendance/data/attendance_repository.dart';
import 'package:shiftly/features/shifts/data/api_shift_repository.dart';
import 'package:shiftly/features/shifts/data/shift_repository.dart';

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

Map<String, Object?> _employee() => {
  'id': 'membership-id',
  'profileId': 'profile-id',
  'fullName': 'Mariam Hassan',
  'email': 'mariam@example.test',
  'phone': null,
  'avatarUrl': null,
  'jobTitle': 'Cashier',
  'role': 'EMPLOYEE',
  'status': 'ACTIVE',
  'joinedAt': '2026-09-01T00:00:00.000Z',
};

Map<String, Object?> _shift({String status = 'SCHEDULED'}) => {
  'id': 'shift-id',
  'workspaceId': 'workspace-id',
  'employeeMembershipId': 'membership-id',
  'createdByMembershipId': 'manager-membership-id',
  'startsAt': '2026-09-26T06:00:00.000Z',
  'endsAt': '2026-09-26T14:00:00.000Z',
  'breakMinutes': 30,
  'graceMinutes': 10,
  'notes': null,
  'status': status,
  'createdAt': '2026-09-20T00:00:00.000Z',
  'updatedAt': '2026-09-20T00:00:00.000Z',
  'employee': _employee(),
  'attendance': null,
};

Map<String, Object?> _attendance({String reviewStatus = 'PENDING'}) => {
  'id': 'attendance-id',
  'workspaceId': 'workspace-id',
  'shiftId': 'shift-id',
  'employeeMembershipId': 'membership-id',
  'clockInAt': '2026-09-26T06:05:00.000Z',
  'clockOutAt': null,
  'reviewStatus': reviewStatus,
  'reviewedByMembershipId': null,
  'reviewedAt': null,
  'rejectionReason': null,
  'minutesLate': 0,
  'workedMinutes': null,
  'createdAt': '2026-09-26T06:05:00.000Z',
  'updatedAt': '2026-09-26T06:05:00.000Z',
  'shift': {
    'id': 'shift-id',
    'startsAt': '2026-09-26T06:00:00.000Z',
    'endsAt': '2026-09-26T14:00:00.000Z',
    'breakMinutes': 30,
    'graceMinutes': 10,
    'notes': null,
    'status': 'SCHEDULED',
  },
  'employee': _employee(),
};

Map<String, Object?> _page(Object record) => {
  'data': [record],
  'pagination': {'page': 1, 'limit': 20, 'total': 1, 'totalPages': 1},
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
    'shift repository sends exact manager routes, filters, and UTC payload',
    () async {
      final client = _client((options) {
        final isCollection =
            options.method == 'GET' &&
            options.uri.path.endsWith('/workspace-id/shifts');
        final status = options.uri.path.endsWith('/cancel')
            ? 'CANCELLED'
            : 'SCHEDULED';
        return isCollection
            ? _json(_page(_shift()))
            : _json(
                _shift(status: status),
                status: options.method == 'POST' ? 201 : 200,
              );
      });
      final repository = ApiShiftRepository(client.dio);
      await repository.listWorkspaceShifts(
        'workspace-id',
        ShiftQuery(
          page: 2,
          employeeMembershipId: 'membership-id',
          status: ShiftStatus.scheduled,
          from: DateTime.parse('2026-09-01T02:00:00+02:00'),
        ),
      );
      await repository.createShift(
        'workspace-id',
        CreateShiftInput(
          employeeMembershipId: 'membership-id',
          startsAt: DateTime.parse('2026-09-26T08:00:00+02:00'),
          endsAt: DateTime.parse('2026-09-26T16:00:00+02:00'),
          breakMinutes: 30,
          graceMinutes: 10,
          notes: ' Front desk ',
        ),
      );
      await repository.getWorkspaceShift('workspace-id', 'shift-id');
      await repository.updateShift(
        'workspace-id',
        'shift-id',
        const UpdateShiftInput(breakMinutes: 45, notes: ' Updated '),
      );
      final cancelled = await repository.cancelShift(
        'workspace-id',
        'shift-id',
      );

      expect(
        client.adapter.requests.first.uri.path,
        '/api/v1/workspaces/workspace-id/shifts',
      );
      expect(client.adapter.requests.first.queryParameters, {
        'page': 2,
        'limit': 20,
        'from': '2026-09-01T00:00:00.000Z',
        'employeeMembershipId': 'membership-id',
        'status': 'SCHEDULED',
      });
      expect(client.adapter.requests[1].data, {
        'employeeMembershipId': 'membership-id',
        'startsAt': '2026-09-26T06:00:00.000Z',
        'endsAt': '2026-09-26T14:00:00.000Z',
        'breakMinutes': 30,
        'graceMinutes': 10,
        'notes': 'Front desk',
      });
      expect(
        client.adapter.requests[2].uri.path,
        '/api/v1/workspaces/workspace-id/shifts/shift-id',
      );
      expect(client.adapter.requests[3].data, {
        'breakMinutes': 45,
        'notes': 'Updated',
      });
      expect(
        client.adapter.requests[4].uri.path,
        '/api/v1/workspaces/workspace-id/shifts/shift-id/cancel',
      );
      expect(cancelled.status, ShiftStatus.cancelled);
    },
  );

  test('employee shift routes exclude unsupported employee filter', () async {
    final client = _client(
      (options) => _json(
        options.uri.path.endsWith('/shift-id') ? _shift() : _page(_shift()),
      ),
    );
    final repository = ApiShiftRepository(client.dio);
    final page = await repository.listMyShifts(
      const ShiftQuery(employeeMembershipId: 'must-not-be-sent'),
    );
    await repository.getMyShift('shift-id');
    expect(client.adapter.requests.first.uri.path, '/api/v1/shifts/me');
    expect(
      client.adapter.requests.first.queryParameters,
      isNot(contains('employeeMembershipId')),
    );
    expect(client.adapter.requests.last.uri.path, '/api/v1/shifts/me/shift-id');
    expect(page.data.single.startsAt.isUtc, isTrue);
  });

  test(
    'attendance repository uses clock, request, review, and employee routes',
    () async {
      final client = _client((options) {
        if (options.uri.path.endsWith('/attendance') ||
            options.uri.path.endsWith('/requests') ||
            options.uri.path.endsWith('/attendance/me')) {
          return _json(_page(_attendance()));
        }
        return _json(
          _attendance(
            reviewStatus: options.uri.path.endsWith('/review')
                ? 'REJECTED'
                : 'PENDING',
          ),
        );
      });
      final repository = ApiAttendanceRepository(client.dio);
      await repository.clockIn('shift-id');
      await repository.clockOut('shift-id');
      await repository.listWorkspaceAttendance(
        'workspace-id',
        const AttendanceQuery(
          employeeMembershipId: 'membership-id',
          reviewStatus: AttendanceReviewStatus.pending,
          shiftStatus: ShiftStatus.scheduled,
        ),
      );
      await repository.listAttendanceRequests(
        'workspace-id',
        page: 2,
        limit: 10,
      );
      await repository.getWorkspaceAttendance('workspace-id', 'attendance-id');
      final reviewed = await repository.reviewAttendance(
        'workspace-id',
        'attendance-id',
        AttendanceReviewDecision.rejected,
        rejectionReason: ' Missing checkout ',
      );
      await repository.listMyAttendance(
        const AttendanceQuery(
          employeeMembershipId: 'must-not-be-sent',
          shiftStatus: ShiftStatus.completed,
        ),
      );

      expect(
        client.adapter.requests[0].uri.path,
        '/api/v1/shifts/shift-id/clock-in',
      );
      expect(
        client.adapter.requests[1].uri.path,
        '/api/v1/shifts/shift-id/clock-out',
      );
      expect(
        client.adapter.requests[2].uri.path,
        '/api/v1/workspaces/workspace-id/attendance',
      );
      expect(client.adapter.requests[2].queryParameters, {
        'page': 1,
        'limit': 20,
        'employeeMembershipId': 'membership-id',
        'reviewStatus': 'PENDING',
        'shiftStatus': 'SCHEDULED',
      });
      expect(
        client.adapter.requests[3].uri.path,
        '/api/v1/workspaces/workspace-id/attendance/requests',
      );
      expect(client.adapter.requests[3].queryParameters, {
        'page': 2,
        'limit': 10,
      });
      expect(
        client.adapter.requests[4].uri.path,
        '/api/v1/workspaces/workspace-id/attendance/attendance-id',
      );
      expect(client.adapter.requests[5].data, {
        'decision': 'REJECTED',
        'rejectionReason': 'Missing checkout',
      });
      expect(reviewed.reviewStatus, AttendanceReviewStatus.rejected);
      expect(
        client.adapter.requests.last.queryParameters,
        isNot(anyOf(contains('employeeMembershipId'), contains('shiftStatus'))),
      );
    },
  );

  test(
    'malformed shift success and attendance backend errors are safe',
    () async {
      final malformed = _client((_) => _json({'id': 'shift-id'}));
      await expectLater(
        ApiShiftRepository(malformed.dio).getMyShift('shift-id'),
        throwsA(
          isA<ApiException>().having(
            (error) => error.message,
            'message',
            'Something went wrong. Please try again.',
          ),
        ),
      );
      final backend = _client(
        (_) => _json({
          'statusCode': 409,
          'code': 'ATTENDANCE_ALREADY_EXISTS',
          'message': 'private backend detail',
          'requestId': 'request-id',
        }, status: 409),
      );
      await expectLater(
        ApiAttendanceRepository(backend.dio).clockIn('shift-id'),
        throwsA(
          isA<ApiException>()
              .having(
                (error) => error.code,
                'code',
                'ATTENDANCE_ALREADY_EXISTS',
              )
              .having((error) => error.requestId, 'requestId', 'request-id'),
        ),
      );
    },
  );
}
