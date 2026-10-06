import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shiftly/core/error/api_exception.dart';
import 'package:shiftly/core/error/failure.dart';
import 'package:shiftly/core/network/api_model_parser.dart';
import 'package:shiftly/core/session/feature_scope.dart';
import 'package:shiftly/features/auth/data/models/current_user.dart';
import 'package:shiftly/features/fixed_shifts/data/api_fixed_shift_repository.dart';
import 'package:shiftly/features/fixed_shifts/data/fixed_shift_repository.dart';
import 'package:shiftly/features/fixed_shifts/presentation/cubit/fixed_shifts_cubit.dart';
import 'package:shiftly/features/fixed_shifts/presentation/widgets/flexible_attendance_panel.dart';

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

ResponseBody _json(Object? value, {int status = 200}) =>
    ResponseBody.fromString(
      jsonEncode(value),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );

Map<String, Object?> _template({
  String id = 'template-id',
  bool active = true,
}) => {
  'id': id,
  'workspaceId': 'workspace-id',
  'name': 'Night operations',
  'description': null,
  'color': '#334155',
  'startMinute': 1320,
  'endMinute': 360,
  'graceMinutes': 10,
  'allowedEarlyCheckInMinutes': 30,
  'allowedLateCheckInMinutes': 120,
  'minimumWorkMinutes': 420,
  'createdByMembershipId': 'manager-id',
  'archivedAt': active ? null : '2026-10-06T10:00:00.000Z',
  'createdAt': '2026-10-01T10:00:00.000Z',
  'updatedAt': '2026-10-01T10:00:00.000Z',
  'active': active,
  'overnight': true,
};

Map<String, Object?> _attendance({String? clockOutAt}) => {
  'id': 'attendance-id',
  'workspaceId': 'workspace-id',
  'shiftId': null,
  'shiftTemplateId': 'template-id',
  'clientAttendanceId': '11111111-1111-4111-8111-111111111111',
  'source': 'TEMPLATE',
  'templateName': 'Night operations',
  'workspaceTimezone': 'Africa/Cairo',
  'operationalDate': '2026-10-06T00:00:00.000Z',
  'scheduledStartAt': '2026-10-06T19:00:00.000Z',
  'scheduledEndAt': '2026-10-07T03:00:00.000Z',
  'graceMinutesUsed': 10,
  'minimumWorkMinutesUsed': 420,
  'clockInClassification': 'ON_TIME',
  'employeeMembershipId': 'employee-membership-id',
  'clockInAt': '2026-10-06T19:01:00.000Z',
  'clockOutAt': clockOutAt,
  'reviewStatus': 'PENDING',
  'reviewedByMembershipId': null,
  'reviewedAt': null,
  'rejectionReason': null,
  'minutesLate': 0,
  'workedMinutes': clockOutAt == null ? null : 480,
  'createdAt': '2026-10-06T19:01:00.000Z',
  'updatedAt': '2026-10-06T19:01:00.000Z',
  'shift': null,
  'shiftTemplate': {
    'id': 'template-id',
    'name': 'Night operations',
    'color': '#334155',
    'archivedAt': null,
  },
  'employee': {'id': 'employee-membership-id'},
};

Map<String, Object?> _page(Object item) => {
  'data': [item],
  'pagination': {'page': 1, 'limit': 100, 'total': 1, 'totalPages': 1},
};

Future<({ApiFixedShiftRepository repository, _Adapter adapter})> _client(
  FutureOr<ResponseBody> Function(RequestOptions options) handler,
) async {
  SharedPreferences.setMockInitialValues({});
  final preferences = await SharedPreferences.getInstance();
  final adapter = _Adapter(handler);
  final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test/api/v1'))
    ..httpClientAdapter = adapter;
  return (
    repository: ApiFixedShiftRepository(dio, preferences),
    adapter: adapter,
  );
}

const _employeeScope = FeatureSessionScope(
  userId: 'employee-user',
  workspaceId: 'workspace-id',
  membershipId: 'employee-membership-id',
  timezone: 'Africa/Cairo',
  role: WorkspaceRole.employee,
  generation: 7,
);

class _FakeRepository implements FixedShiftRepository {
  PendingClockIn? pending;
  final clockInIds = <String>[];
  Completer<ShiftTemplatePage>? templateCompleter;
  var refreshFails = false;

  ShiftTemplate get template => ShiftTemplate.fromJson(_template());
  EligibleShiftOccurrence get occurrence => EligibleShiftOccurrence(
    template: template,
    operationalDate: '2026-10-06',
    scheduledStartAt: DateTime.utc(2026, 10, 6, 19),
    scheduledEndAt: DateTime.utc(2026, 10, 7, 3),
    checkInWindowStart: DateTime.utc(2026, 10, 6, 18, 30),
    checkInWindowEnd: DateTime.utc(2026, 10, 7, 3),
    classification: AttendanceClassification.onTime,
    lateMinutes: 0,
    recommended: true,
  );
  FlexibleAttendance attendance({String? clockOutAt}) =>
      FlexibleAttendance.fromJson(_attendance(clockOutAt: clockOutAt));
  ShiftTemplatePage get page => ShiftTemplatePage(
    data: [template],
    pagination: const ApiPagination(
      page: 1,
      limit: 100,
      total: 1,
      totalPages: 1,
    ),
  );

  @override
  Future<ShiftTemplatePage> listTemplates(
    String workspaceId, {
    bool includeArchived = false,
    int page = 1,
    int limit = 100,
  }) => templateCompleter?.future ?? Future.value(this.page);
  @override
  Future<ShiftTemplatePage> listMyTemplates(
    String workspaceId, {
    int page = 1,
    int limit = 100,
  }) async {
    if (refreshFails) throw const ApiException(message: 'offline');
    return this.page;
  }

  @override
  Future<TemplateEligibility> getEligibility(String workspaceId) async {
    if (refreshFails) throw const ApiException(message: 'offline');
    return TemplateEligibility(
      workspaceId: workspaceId,
      timezone: 'Africa/Cairo',
      evaluatedAt: DateTime.utc(2026, 10, 6, 19),
      recommended: occurrence,
      eligibleTemplates: [occurrence],
    );
  }

  @override
  Future<FlexibleAttendance?> getCurrentAttendance(String workspaceId) async =>
      null;
  @override
  Future<FlexibleAttendance> flexibleClockIn({
    required String workspaceId,
    required String shiftTemplateId,
    required String clientAttendanceId,
  }) async {
    clockInIds.add(clientAttendanceId);
    if (clockInIds.length == 1) {
      throw const ApiException(message: 'timeout', kind: FailureKind.timeout);
    }
    return attendance();
  }

  @override
  Future<FlexibleAttendance> flexibleClockOut(String attendanceId) async =>
      attendance(clockOutAt: '2026-10-07T03:01:00.000Z');
  @override
  Future<PendingClockIn?> loadPendingClockIn() async => pending;
  @override
  Future<void> savePendingClockIn(PendingClockIn value) async =>
      pending = value;
  @override
  Future<void> clearPendingClockIn() async => pending = null;
  @override
  Future<ShiftTemplate> createTemplate(
    String workspaceId,
    ShiftTemplateInput input,
  ) async => template;
  @override
  Future<ShiftTemplate> updateTemplate(
    String workspaceId,
    String templateId,
    ShiftTemplateInput input,
  ) async => template;
  @override
  Future<ShiftTemplate> archiveTemplate(
    String workspaceId,
    String templateId,
  ) async => ShiftTemplate.fromJson(_template(active: false));
  @override
  Future<ShiftTemplate> getTemplate(
    String workspaceId,
    String templateId,
  ) async => template;
  @override
  Future<WorkPatternHistory> getWorkPatterns(
    String workspaceId,
    String membershipId,
  ) async => const WorkPatternHistory(current: null, history: []);
  @override
  Future<WorkPattern> replaceWorkPattern(
    String workspaceId,
    String membershipId, {
    required List<int> expectedWeekdays,
    required String effectiveFrom,
  }) => throw UnimplementedError();
}

void main() {
  test('manager template repository uses exact paths, query, payload, and archive verb', () async {
    final client = await _client(
      (options) => _json(
        options.method == 'GET' && !options.uri.path.endsWith('template-id')
            ? _page(_template())
            : _template(),
        status: options.method == 'POST' ? 201 : 200,
      ),
    );
    const input = ShiftTemplateInput(
      name: ' Night ',
      color: '#334155',
      startMinute: 1320,
      endMinute: 360,
      graceMinutes: 10,
      allowedEarlyCheckInMinutes: 30,
      allowedLateCheckInMinutes: 120,
      minimumWorkMinutes: 420,
    );
    await client.repository.listTemplates(
      'workspace-id',
      includeArchived: true,
    );
    await client.repository.createTemplate('workspace-id', input);
    await client.repository.getTemplate('workspace-id', 'template-id');
    await client.repository.updateTemplate(
      'workspace-id',
      'template-id',
      input,
    );
    await client.repository.archiveTemplate('workspace-id', 'template-id');
    expect(
      client.adapter.requests.first.uri.path,
      '/api/v1/workspaces/workspace-id/shift-templates',
    );
    expect(client.adapter.requests.first.queryParameters, {
      'page': 1,
      'limit': 100,
      'includeArchived': true,
    });
    expect(client.adapter.requests[1].data, containsPair('name', 'Night'));
    expect(client.adapter.requests.last.method, 'DELETE');
  });

  test('work patterns and employee attendance use exact contracts', () async {
    final client = await _client((options) {
      if (options.uri.path.endsWith('/work-patterns')) {
        return _json(
          options.method == 'GET'
              ? {'current': null, 'history': []}
              : {
                  'id': 'pattern-id',
                  'workspaceId': 'workspace-id',
                  'employeeMembershipId': 'membership-id',
                  'expectedWeekdays': [1, 3],
                  'effectiveFrom': '2026-10-06',
                  'effectiveTo': null,
                  'createdAt': '2026-10-06T00:00:00.000Z',
                  'updatedAt': '2026-10-06T00:00:00.000Z',
                },
        );
      }
      if (options.uri.path.endsWith('/eligibility')) {
        return _json({
          'workspaceId': 'workspace-id',
          'timezone': 'Africa/Cairo',
          'evaluatedAt': '2026-10-06T19:00:00.000Z',
          'recommended': null,
          'eligibleTemplates': [],
        });
      }
      if (options.uri.path.endsWith('/me')) {
        return _json(_page(_template()));
      }
      if (options.uri.path.endsWith('/current')) {
        return _json(null);
      }
      return _json(
        _attendance(
          clockOutAt: options.uri.path.endsWith('/clock-out')
              ? '2026-10-07T03:01:00.000Z'
              : null,
        ),
        status: 201,
      );
    });
    await client.repository.getWorkPatterns('workspace-id', 'membership-id');
    await client.repository.replaceWorkPattern(
      'workspace-id',
      'membership-id',
      expectedWeekdays: [3, 1],
      effectiveFrom: '2026-10-06',
    );
    await client.repository.listMyTemplates('workspace-id');
    await client.repository.getEligibility('workspace-id');
    expect(
      await client.repository.getCurrentAttendance('workspace-id'),
      isNull,
    );
    await client.repository.flexibleClockIn(
      workspaceId: 'workspace-id',
      shiftTemplateId: 'template-id',
      clientAttendanceId: '11111111-1111-4111-8111-111111111111',
    );
    await client.repository.flexibleClockOut('attendance-id');
    expect(client.adapter.requests[1].data, {
      'expectedWeekdays': [1, 3],
      'effectiveFrom': '2026-10-06',
    });
    expect(client.adapter.requests[4].queryParameters, {
      'workspaceId': 'workspace-id',
    });
    expect(client.adapter.requests[5].data, {
      'workspaceId': 'workspace-id',
      'shiftTemplateId': 'template-id',
      'clientAttendanceId': '11111111-1111-4111-8111-111111111111',
    });
    expect(
      client.adapter.requests[6].uri.path,
      '/api/v1/attendance/attendance-id/clock-out',
    );
  });

  test(
    'unknown enums remain non-actionable and malformed success is safe',
    () async {
      final unknown = EligibleShiftOccurrence.fromJson({
        'template': _template(),
        'operationalDate': '2026-10-06',
        'scheduledStartAt': '2026-10-06T19:00:00.000Z',
        'scheduledEndAt': '2026-10-07T03:00:00.000Z',
        'checkInWindowStart': '2026-10-06T18:30:00.000Z',
        'checkInWindowEnd': '2026-10-07T03:00:00.000Z',
        'expectedClockInClassification': 'FUTURE_VALUE',
        'lateMinutes': 0,
        'recommended': false,
      });
      expect(unknown.classification, AttendanceClassification.unknown);
      expect(unknown.canClockIn, isFalse);
      final client = await _client((_) => _json({'id': 'broken'}));
      await expectLater(
        client.repository.getTemplate('workspace-id', 'template-id'),
        throwsA(isA<ApiException>()),
      );
    },
  );

  test('pending clock-in survives timeout and reuses the same UUID', () async {
    final repository = _FakeRepository();
    final cubit = FlexibleAttendanceCubit(
      repository,
      uuid: () => '11111111-1111-4111-8111-111111111111',
    )..bindSession(_employeeScope);
    addTearDown(cubit.close);
    await cubit.stream.firstWhere((state) => !state.loading);
    expect(
      await cubit.clockIn(repository.occurrence),
      FixedShiftMutationResult.failure,
    );
    expect(repository.pending, isNotNull);
    expect(
      await cubit.clockIn(repository.occurrence),
      FixedShiftMutationResult.success,
    );
    expect(repository.clockInIds, [
      '11111111-1111-4111-8111-111111111111',
      '11111111-1111-4111-8111-111111111111',
    ]);
    expect(repository.pending, isNull);
  });

  test(
    'role and generation changes clear state and reject stale responses',
    () async {
      final repository = _FakeRepository()
        ..templateCompleter = Completer<ShiftTemplatePage>();
      final cubit = ManagerTemplatesCubit(repository)
        ..bindSession(
          const FeatureSessionScope(
            userId: 'manager',
            workspaceId: 'workspace-id',
            membershipId: 'manager-membership',
            timezone: 'Africa/Cairo',
            role: WorkspaceRole.manager,
            generation: 1,
          ),
        );
      addTearDown(cubit.close);
      cubit.bindSession(
        const FeatureSessionScope(
          userId: 'manager',
          workspaceId: 'workspace-2',
          membershipId: 'manager-membership-2',
          timezone: 'Africa/Cairo',
          role: WorkspaceRole.manager,
          generation: 2,
        ),
      );
      cubit.bindSession(null);
      repository.templateCompleter!.complete(repository.page);
      await Future<void>.delayed(Duration.zero);
      expect(cubit.state.templates, isEmpty);
      expect(cubit.state.loading, isTrue);
    },
  );

  test(
    'suspended membership never triggers employee protected requests',
    () async {
      final repository = _FakeRepository();
      final cubit = FlexibleAttendanceCubit(repository)
        ..bindSession(
          const FeatureSessionScope(
            userId: 'employee-user',
            workspaceId: 'workspace-id',
            membershipId: 'employee-membership-id',
            timezone: 'Africa/Cairo',
            role: WorkspaceRole.employee,
            membershipStatus: MembershipStatus.suspended,
          ),
        );
      addTearDown(cubit.close);
      await Future<void>.delayed(Duration.zero);
      expect(cubit.state.loading, isTrue);
      expect(repository.clockInIds, isEmpty);
    },
  );

  test(
    'template duration validation covers same-day, overnight, and 24-hour',
    () {
      ShiftTemplateInput input(int start, int end, int minimum) =>
          ShiftTemplateInput(
            name: 'Template',
            color: '#334155',
            startMinute: start,
            endMinute: end,
            graceMinutes: 0,
            allowedEarlyCheckInMinutes: 0,
            allowedLateCheckInMinutes: 0,
            minimumWorkMinutes: minimum,
          );
      expect(input(540, 1020, 480).durationMinutes, 480);
      expect(input(1320, 360, 480).durationMinutes, 480);
      expect(input(540, 540, 1440).durationMinutes, 1440);
      expect(input(540, 1020, 481).validate(), isNotNull);
    },
  );

  testWidgets('recommended eligibility is readable on a narrow screen', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final repository = _FakeRepository();
    final cubit = FlexibleAttendanceCubit(repository)
      ..bindSession(_employeeScope);
    addTearDown(cubit.close);
    await cubit.stream.firstWhere((state) => !state.loading);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BlocProvider.value(
            value: cubit,
            child: const SingleChildScrollView(
              child: FlexibleAttendancePanel(timezone: 'Africa/Cairo'),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Recommended'), findsOneWidget);
    expect(find.textContaining('On time'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
