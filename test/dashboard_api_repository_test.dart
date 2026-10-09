import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shiftly/core/error/api_exception.dart';
import 'package:shiftly/features/dashboard/data/api_dashboard_repository.dart';
import 'package:shiftly/features/shifts/domain/repositories/shift_repository.dart';

import 'dashboard_fixtures.dart';

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
  test('uses exact authenticated manager and employee endpoints', () async {
    final client = _client(
      (options) => _json(
        options.uri.path.endsWith('/dashboard/me')
            ? employeeDashboardJson()
            : managerDashboardJson(),
      ),
    );
    final repository = ApiDashboardRepository(client.dio);
    final manager = await repository.getManagerDashboard(dashboardWorkspaceId);
    final employee = await repository.getEmployeeDashboard(
      dashboardWorkspaceId,
    );

    expect(client.adapter.requests[0].method, 'GET');
    expect(
      client.adapter.requests[0].uri.path,
      '/api/v1/workspaces/$dashboardWorkspaceId/dashboard',
    );
    expect(client.adapter.requests[0].queryParameters, isEmpty);
    expect(
      client.adapter.requests[0].headers['Authorization'],
      'Bearer test-token',
    );
    expect(client.adapter.requests[1].uri.path, '/api/v1/dashboard/me');
    expect(client.adapter.requests[1].queryParameters, {
      'workspaceId': dashboardWorkspaceId,
    });
    expect(manager.summary.totalEmployees, 12);
    expect(manager.generatedAt.isUtc, isTrue);
    expect(manager.todayShifts.single.startsAt.isUtc, isTrue);
    expect(employee.employee.membershipId, dashboardMembershipId);
    expect(employee.attendance?.clockedOutAt, isNull);
    expect(employee.generatedAt.isUtc, isTrue);
  });

  test('parses zero, large, nullable, and unknown values safely', () async {
    final managerJson = managerDashboardJson(
      totalEmployees: 0,
      scheduledToday: 999999999,
      clockedInNow: 0,
      completedToday: 0,
      lateToday: 0,
      missedToday: 0,
      onApprovedLeave: 0,
      pendingLeaveRequests: 0,
      unreadNotifications: 0,
      todayShifts: [dashboardShiftJson(status: 'FUTURE_STATUS')],
      pendingLeaves: [],
    );
    final employeeJson = employeeDashboardJson(
      todayShift: null,
      attendance: null,
      nextShift: null,
    );
    final client = _client(
      (options) => _json(
        options.uri.path.endsWith('/dashboard/me') ? employeeJson : managerJson,
      ),
    );
    final repository = ApiDashboardRepository(client.dio);
    final manager = await repository.getManagerDashboard(dashboardWorkspaceId);
    final employee = await repository.getEmployeeDashboard(
      dashboardWorkspaceId,
    );
    expect(manager.summary.totalEmployees, 0);
    expect(manager.summary.scheduledToday, 999999999);
    expect(manager.todayShifts.single.status, ShiftStatus.unknown);
    expect(employee.todayShift, isNull);
    expect(employee.attendance, isNull);
    expect(employee.nextShift, isNull);
  });

  test('rejects malformed and negative successful responses', () async {
    final malformed = managerDashboardJson();
    (malformed['summary']! as Map<String, Object?>)['totalEmployees'] = -1;
    final client = _client((_) => _json(malformed));
    await expectLater(
      ApiDashboardRepository(client.dio)
          .getManagerDashboard(dashboardWorkspaceId),
      throwsA(isA<ApiException>()),
    );
  });

  test('preserves typed backend errors and requestId', () async {
    final client = _client(
      (_) => _json({
        'statusCode': 403,
        'code': 'WORKSPACE_ACCESS_DENIED',
        'message': 'private detail',
        'requestId': 'dashboard-request-id',
      }, status: 403),
    );
    await expectLater(
      ApiDashboardRepository(client.dio)
          .getManagerDashboard(dashboardWorkspaceId),
      throwsA(
        isA<ApiException>()
            .having((error) => error.statusCode, 'statusCode', 403)
            .having(
              (error) => error.requestId,
              'requestId',
              'dashboard-request-id',
            )
            .having(
              (error) => error.message,
              'message',
              'Your workspace membership does not allow this action.',
            ),
      ),
    );
  });
}
