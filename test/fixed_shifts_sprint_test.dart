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
import 'package:shiftly/core/serialization/api_model_parser.dart';
import 'package:shiftly/core/session/feature_scope.dart';
import 'package:shiftly/core/utils/workspace_timestamp_input.dart';
import 'package:shiftly/features/attendance/domain/repositories/attendance_repository.dart';
import 'package:shiftly/features/auth/domain/entities/current_user.dart';
import 'package:shiftly/features/fixed_shifts/data/api_fixed_shift_repository.dart';
import 'package:shiftly/features/fixed_shifts/domain/entities/extra_authorization.dart';
import 'package:shiftly/features/fixed_shifts/domain/entities/extra_authorization_page.dart';
import 'package:shiftly/features/fixed_shifts/domain/repositories/extra_shift_repository.dart';
import 'package:shiftly/features/fixed_shifts/domain/repositories/fixed_shift_repository.dart';
import 'package:shiftly/features/fixed_shifts/presentation/cubit/extra_shifts_cubit.dart';
import 'package:shiftly/features/fixed_shifts/presentation/cubit/fixed_shifts_cubit.dart';
import 'package:shiftly/features/fixed_shifts/presentation/screens/shift_templates_screen.dart';
import 'package:shiftly/features/fixed_shifts/presentation/widgets/assignment_form.dart';
import 'package:shiftly/features/fixed_shifts/presentation/widgets/extra_shift_form.dart';
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
  String name = 'Night operations',
}) => {
  'id': id,
  'workspaceId': 'workspace-id',
  'name': name,
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
  'occurrenceKind': 'BASELINE',
  'assignmentId': 'assignment-id',
  'extraAuthorizationId': null,
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
  'employee': {
    'id': 'employee-membership-id',
    'profileId': 'profile-id',
    'role': 'EMPLOYEE',
    'status': 'ACTIVE',
  },
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

const _managerScope = FeatureSessionScope(
  userId: 'manager-user',
  workspaceId: 'workspace-id',
  membershipId: 'manager-membership-id',
  timezone: 'Africa/Cairo',
  role: WorkspaceRole.manager,
  generation: 7,
);

class _FakeRepository implements FixedShiftRepository {
  PendingClockIn? pending;
  final clockInIds = <String>[];
  Completer<ShiftTemplatePage>? templateCompleter;
  var refreshFails = false;
  List<ShiftTemplate>? templateValues;

  ShiftTemplate get template => ShiftTemplate.fromJson(_template());
  EligibleShiftOccurrence get occurrence => EligibleShiftOccurrence(
    occurrenceKind: 'BASELINE',
    assignmentId: 'assignment-id',
    eligible: true,
    alreadyUsed: false,
    timezone: 'Africa/Cairo',
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
    data: templateValues ?? [template],
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
    if (refreshFails) {
      throw const ApiException(message: 'offline');
    }
    return this.page;
  }

  @override
  Future<TemplateEligibility> getEligibility(String workspaceId) async {
    if (refreshFails) {
      throw const ApiException(message: 'offline');
    }
    return TemplateEligibility(
      workspaceId: workspaceId,
      timezone: 'Africa/Cairo',
      evaluatedAt: DateTime.utc(2026, 10, 6, 19),
      status: 'ASSIGNED',
      authorizedOccurrences: [occurrence],
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
    String? assignmentId,
    String? extraAuthorizationId,
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
  Future<PendingClockIn?> loadPendingClockIn({
    required String userId,
    required String workspaceId,
    required String membershipId,
    required String templateId,
  }) async =>
      pending?.matches(
            userId: userId,
            workspaceId: workspaceId,
            membershipId: membershipId,
            templateId: pending!.templateId,
          ) ==
          true
      ? pending
      : null;
  @override
  Future<FlexibleAttendance?> findPendingAttendance(
    PendingClockIn value,
  ) async => null;
  @override
  Future<void> savePendingClockIn(PendingClockIn value) async =>
      pending = value;
  @override
  Future<void> clearPendingClockIn(PendingClockIn value) async {
    if (pending == value) {
      pending = null;
    }
  }

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
    String membershipId, {
    int page = 1,
    int limit = 20,
  }) async => const WorkPatternHistory(current: null, history: []);
  @override
  Future<WorkPattern> replaceWorkPattern(
    String workspaceId,
    String membershipId, {
    required String shiftTemplateId,
    required List<int> expectedWeekdays,
    required String effectiveFrom,
  }) => throw UnimplementedError();
}

class _WorkPatternRaceRepository extends _FakeRepository {
  final requests = <Completer<WorkPatternHistory>>[];

  @override
  Future<WorkPatternHistory> getWorkPatterns(
    String workspaceId,
    String membershipId, {
    int page = 1,
    int limit = 20,
  }) {
    final request = Completer<WorkPatternHistory>();
    requests.add(request);
    return request.future;
  }
}

void main() {
  test('completed extra history without attendance relation permits another authorization', () async {
    final completed = _extraJson({
      ..._extraPayload(),
      'clientAuthorizationId': '11111111-1111-4111-8111-111111111111',
    }, status: 'CONSUMED')..remove('attendance');
    completed['operationalDate'] = '2026-10-06T00:00:00.000Z';
    final client = await _client(
      (options) => options.method == 'GET'
          ? _json(_page(completed))
          : _json(_extraJson(Map<String, Object?>.from(options.data as Map))),
    );
    final cubit = ExtraShiftsCubit(client.repository)
      ..bind(_managerScope, 'membership-id');
    addTearDown(cubit.close);
    await cubit.load();
    expect(cubit.state.failure, isNull);
    expect(cubit.state.recoveryBlocked, isFalse);
    expect(cubit.state.page!.data.single.status, 'CONSUMED');
    expect(cubit.state.page!.data.single.operationalDate, '2026-10-06');
    expect(
      await cubit.create({
        ..._extraPayload(),
        'operationalDate': '2026-10-07',
      }, actual: false),
      isTrue,
    );
    expect(cubit.state.failure, isNull);
    expect(cubit.state.intent, isNull);
    expect(cubit.state.recoveryBlocked, isFalse);
    expect(
      client.adapter.requests.where((r) => r.method == 'POST'),
      hasLength(1),
    );
  });

  test(
    'actual extra creation still requires linked attendance evidence',
    () async {
      final client = await _client(
        (options) => options.method == 'GET'
            ? _json({
                'data': [],
                'pagination': {
                  'page': 1,
                  'limit': 20,
                  'total': 0,
                  'totalPages': 0,
                },
              })
            : _json(
                _extraJson(
                  Map<String, Object?>.from(options.data as Map),
                  status: 'CONSUMED',
                )..remove('attendance'),
              ),
      );
      final cubit = ExtraShiftsCubit(client.repository)
        ..bind(_managerScope, 'membership-id');
      addTearDown(cubit.close);
      await cubit.load();
      expect(
        await cubit.create({
          ..._extraPayload(),
          'actualClockInAt': '2026-10-06T19:00:00Z',
          'actualClockOutAt': '2026-10-06T23:00:00Z',
        }, actual: true),
        isFalse,
      );
      expect(cubit.state.recoveryBlocked, isTrue);
      expect(cubit.state.intent, isNotNull);
    },
  );
  assignedSprintTests();
  correctiveSprintTests();
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
              ? {
                  'current': null,
                  'history': [],
                  'pagination': {
                    'page': 1,
                    'limit': 20,
                    'total': 0,
                    'totalPages': 0,
                  },
                }
              : {
                  'id': 'pattern-id',
                  'workspaceId': 'workspace-id',
                  'employeeMembershipId': 'membership-id',
                  'shiftTemplateId': 'template-id',
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
      shiftTemplateId: 'template-id',
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
      'shiftTemplateId': 'template-id',
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
      now: () => DateTime.utc(2026, 10, 6, 19),
      uuid: () => '11111111-1111-4111-8111-111111111111',
    )..bindSession(_employeeScope);
    addTearDown(cubit.close);
    await cubit.stream.firstWhere((state) => !state.loading);
    expect(
      await cubit.clockIn(repository.occurrence),
      FixedShiftMutationResult.failure,
    );
    expect(repository.pending, isNotNull);
    expect(await cubit.recoverClockIn(), FixedShiftMutationResult.success);
    expect(repository.clockInIds, [
      '11111111-1111-4111-8111-111111111111',
      '11111111-1111-4111-8111-111111111111',
    ]);
    expect(repository.pending, isNull);
  });

  test(
    'persisted clock-in idempotency is isolated across session scope',
    () async {
      final repository = _FakeRepository()
        ..pending = const PendingClockIn(
          userId: 'old-user',
          workspaceId: 'old-workspace',
          membershipId: 'old-membership',
          templateId: 'template-id',
          clientAttendanceId: '00000000-0000-4000-8000-000000000001',
        );
      final cubit = FlexibleAttendanceCubit(
        repository,
        uuid: () => '22222222-2222-4222-8222-222222222222',
      )..bindSession(_employeeScope);
      addTearDown(cubit.close);
      await cubit.stream.firstWhere((state) => !state.loading);
      expect(
        await cubit.clockIn(repository.occurrence),
        FixedShiftMutationResult.failure,
      );
      expect(repository.clockInIds, ['22222222-2222-4222-8222-222222222222']);
      expect(repository.pending?.userId, _employeeScope.userId);
      expect(repository.pending?.workspaceId, _employeeScope.workspaceId);
      expect(repository.pending?.membershipId, _employeeScope.membershipId);
    },
  );

  test('persisted clock-in records use independent scoped keys', () async {
    final client = await _client((_) => _json(null));
    const first = PendingClockIn(
      userId: 'user-a',
      workspaceId: 'workspace-a',
      membershipId: 'membership-a',
      occurrenceKind: 'BASELINE',
      assignmentId: 'assignment-a',
      operationalDate: '2026-10-06',
      templateId: 'template-a',
      clientAttendanceId: '11111111-1111-4111-8111-111111111111',
    );
    const second = PendingClockIn(
      userId: 'user-b',
      workspaceId: 'workspace-b',
      membershipId: 'membership-b',
      occurrenceKind: 'EXTRA',
      extraAuthorizationId: 'extra-b',
      operationalDate: '2026-10-07',
      templateId: 'template-b',
      clientAttendanceId: '22222222-2222-4222-8222-222222222222',
    );
    await client.repository.savePendingClockIn(first);
    await client.repository.savePendingClockIn(second);
    expect(
      await client.repository.loadPendingClockIn(
        userId: first.userId,
        workspaceId: first.workspaceId,
        membershipId: first.membershipId,
        templateId: first.templateId,
      ),
      isNotNull,
    );
    await client.repository.clearPendingClockIn(first);
    expect(
      await client.repository.loadPendingClockIn(
        userId: second.userId,
        workspaceId: second.workspaceId,
        membershipId: second.membershipId,
        templateId: second.templateId,
      ),
      isNotNull,
    );
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

  test('fixed-shift models reject invalid dates and negative values', () {
    expect(
      () => ShiftTemplate.fromJson({..._template(), 'graceMinutes': -1}),
      throwsFormatException,
    );
    expect(
      () => WorkPattern.fromJson(const {
        'id': 'pattern',
        'workspaceId': 'workspace-id',
        'employeeMembershipId': 'membership-id',
        'expectedWeekdays': [1],
        'effectiveFrom': '2026-02-30',
        'effectiveTo': null,
        'createdAt': '2026-10-06T00:00:00Z',
        'updatedAt': '2026-10-06T00:00:00Z',
      }),
      throwsFormatException,
    );
    expect(
      () => ApiPagination.fromJson({
        'page': 1,
        'limit': 20,
        'total': -1,
        'totalPages': 0,
      }),
      throwsFormatException,
    );
  });

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

  testWidgets(
    'template cards use natural height and final card clears the floating action',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 700));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final repository = _FakeRepository()
        ..templateValues = [
          ShiftTemplate.fromJson(_template(id: 'first')),
          ShiftTemplate.fromJson(
            _template(
              id: 'long',
              name: 'Extremely long overnight customer support and operations shift',
            ),
          ),
          ShiftTemplate.fromJson(_template(id: 'archived', active: false)),
        ];
      final cubit = ManagerTemplatesCubit(repository)
        ..bindSession(_managerScope);
      addTearDown(cubit.close);
      await cubit.stream.firstWhere((state) => !state.loading);
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(320, 700),
              textScaler: TextScaler.linear(1.3),
              viewPadding: EdgeInsets.only(bottom: 24),
            ),
            child: BlocProvider.value(
              value: cubit,
              child: const ShiftTemplatesScreen(
                workspaceName: 'A long workspace name for compact devices',
                timezone: 'Africa/Cairo',
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.scrollUntilVisible(
        find.text('Read-only history'),
        250,
        scrollable: find
            .descendant(
              of: find.byKey(const Key('shift-template-list')),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.drag(
        find.byKey(const Key('shift-template-list')),
        const Offset(0, -180),
      );
      await tester.pumpAndSettle();
      final finalField = tester.getRect(find.text('Read-only history'));
      final floatingButton = tester.getRect(find.text('New template'));
      expect(finalField.bottom, lessThan(floatingButton.top));
      expect(tester.takeException(), isNull);
    },
  );

  test(
    'work pattern loads suppress duplicates and queue one refresh',
    () async {
      final repository = _WorkPatternRaceRepository();
      final cubit = WorkPatternCubit(repository);
      addTearDown(cubit.close);
      unawaited(
        cubit.bind(
          workspaceId: 'workspace-id',
          membershipId: 'membership-id',
          scope: _managerScope,
        ),
      );
      await Future<void>.delayed(Duration.zero);
      expect(repository.requests, hasLength(1));
      unawaited(cubit.load(retain: true));
      unawaited(cubit.load(retain: true));
      expect(repository.requests, hasLength(1));
      repository.requests.first.complete(
        const WorkPatternHistory(current: null, history: []),
      );
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      expect(repository.requests, hasLength(2));
      final current = WorkPattern(
        id: 'pattern-new',
        workspaceId: 'workspace-id',
        employeeMembershipId: 'membership-id',
        expectedWeekdays: const [1, 2, 3],
        effectiveFrom: '2026-10-06',
        createdAt: DateTime.utc(2026, 10, 6),
        updatedAt: DateTime.utc(2026, 10, 6),
      );
      repository.requests.last.complete(
        WorkPatternHistory(current: current, history: [current]),
      );
      await cubit.stream.firstWhere(
        (state) => !state.loading && state.history?.current == current,
      );
      expect(cubit.state.history?.current, current);
    },
  );
}

TemplateEligibility _eligibility(
  _ControlledRepository repository, {
  String status = 'ASSIGNED',
}) => TemplateEligibility(
  workspaceId: 'workspace-id',
  timezone: 'Africa/Cairo',
  evaluatedAt: DateTime.utc(2026, 10, 6, 19),
  status: status,
  recommended: repository.occurrence,
  eligibleTemplates: [repository.occurrence],
  authorizedOccurrences: [repository.occurrence],
);

PendingClockIn _pending() => const PendingClockIn(
  userId: 'employee-user',
  workspaceId: 'workspace-id',
  membershipId: 'employee-membership-id',
  templateId: 'template-id',
  clientAttendanceId: '11111111-1111-4111-8111-111111111111',
  occurrenceKind: 'BASELINE',
  assignmentId: 'assignment-id',
  operationalDate: '2026-10-06',
);

void correctiveSprintTests() {
  test(
    'legacy storage type failure preserves evidence as explicit review',
    () async {
      SharedPreferences.setMockInitialValues({
        'fixed_shift.pending_clock_in.v1': 17,
      });
      final preferences = await SharedPreferences.getInstance();
      final repository = ApiFixedShiftRepository(Dio(), preferences);
      final reviews = await repository.inspectLegacyClockIns(_employeeScope);
      expect(reviews.single.requiresReview, isTrue);
      expect(reviews.single.message, contains('owner or request evidence'));
      expect(preferences.get('fixed_shift.pending_clock_in.v1'), 17);
    },
  );

  testWidgets(
    'ambiguous legacy intent shows review and refresh without a replay action',
    (tester) async {
      final client = await _client((options) {
        if (options.path.endsWith('/current')) {
          return _json(null);
        }
        if (options.path.endsWith('/eligibility')) {
          return _json({
            'workspaceId': 'workspace-id',
            'timezone': 'Africa/Cairo',
            'evaluatedAt': '2026-10-06T19:00:00Z',
            'eligibleTemplates': [],
            'authorizedOccurrences': [],
            'status': 'SHIFT_ASSIGNMENT_REQUIRED',
          });
        }
        return _json({
          'data': [],
          'pagination': {'page': 1, 'limit': 100, 'total': 0, 'totalPages': 0},
        });
      });
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(
        'fixed_shift.pending_clock_in.v1',
        '{ambiguous}',
      );
      final cubit = FlexibleAttendanceCubit(client.repository);
      addTearDown(cubit.close);
      await tester.runAsync(() async {
        cubit.bindSession(_employeeScope);
        await cubit.load();
      });
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BlocProvider.value(
              value: cubit,
              child: const FlexibleAttendancePanel(timezone: 'Africa/Cairo'),
            ),
          ),
        ),
      );
      expect(find.text('Saved legacy clock-in needs review'), findsOneWidget);
      expect(find.text('Check attendance again'), findsOneWidget);
      expect(find.text('Recover saved clock-in'), findsNothing);
      expect(cubit.state.failure, isNull);
      expect(cubit.state.legacyReviewRequired, isTrue);
      expect(client.adapter.requests.every((r) => r.method == 'GET'), isTrue);
    },
  );

  test('held revoke callback keeps all manager mutations serialized', () async {
    final callback = Completer<void>(), started = Completer<void>();
    final repository = _ExtraRepository();
    final cubit = ExtraShiftsCubit(
      repository,
      onChanged: () {
        started.complete();
        return callback.future;
      },
    )..bind(_managerScope, 'membership-id');
    addTearDown(cubit.close);
    await cubit.load();
    final value = ExtraAuthorization(
      _extraJson({
        ..._extraPayload(),
        'clientAuthorizationId': '11111111-1111-4111-8111-111111111111',
      }),
    );
    final first = cubit.revoke(value);
    await started.future;
    expect(await cubit.revoke(value), isFalse);
    expect(await cubit.create(_extraPayload(), actual: false), isFalse);
    expect(await cubit.recover(), isFalse);
    expect(repository.revocations, 1);
    callback.complete();
    expect(await first, isTrue);
    expect(cubit.state.canonical!.status, 'REVOKED');
    expect(cubit.state.busy, isFalse);
  });
  test(
    'captured open attendance cannot overwrite a successful clock-out',
    () async {
      final repository = _ControlledRepository()
        ..current = FlexibleAttendance.fromJson(_attendance());
      final cubit = FlexibleAttendanceCubit(repository)
        ..bindSession(_employeeScope);
      addTearDown(cubit.close);
      await cubit.load();
      final held = Completer<TemplateEligibility>();
      repository.eligibilityReads.add(held);
      repository.eligibilityStarted = Completer<void>();
      final old = cubit.load(refresh: true);
      await repository.eligibilityStarted!.future;
      expect(await cubit.clockOut(), FixedShiftMutationResult.success);
      final closed = cubit.state.current;
      held.complete(_eligibility(repository));
      await old;
      expect(cubit.state.current, closed);
      expect(cubit.state.current!.isOpen, isFalse);
    },
  );

  test('captured recovery cannot resurrect an intent after canonical reconciliation', () async {
    final repository = _ControlledRepository()..pending = _pending();
    repository.saved = FlexibleAttendance.fromJson(_attendance());
    final held = Completer<TemplateEligibility>();
    repository.eligibilityReads.add(held);
    repository.eligibilityStarted = Completer<void>();
    final cubit = FlexibleAttendanceCubit(repository)
      ..bindSession(_employeeScope);
    addTearDown(cubit.close);
    final old = cubit.load();
    await repository.eligibilityStarted!.future;
    expect(cubit.state.recovery, isNotNull);
    expect(await cubit.recoverClockIn(), FixedShiftMutationResult.success);
    held.complete(_eligibility(repository));
    await old;
    expect(cubit.state.current, repository.saved);
    expect(cubit.state.recovery, isNull);
    expect(repository.pending, isNull);
    expect(repository.payloads, isEmpty);
    expect(cubit.state.loading, isFalse);
  });

  test(
    'older post-mutation eligibility cannot replace a newer full refresh',
    () async {
      final repository = _ControlledRepository()
        ..current = FlexibleAttendance.fromJson(_attendance());
      final cubit = FlexibleAttendanceCubit(repository)
        ..bindSession(_employeeScope);
      addTearDown(cubit.close);
      await cubit.load();
      final held = Completer<TemplateEligibility>();
      repository.eligibilityReads.add(held);
      repository.eligibilityStarted = Completer<void>();
      expect(await cubit.clockOut(), FixedShiftMutationResult.success);
      await repository.eligibilityStarted!.future;
      repository.eligibilityStatus = 'SHIFT_ASSIGNMENT_REQUIRED';
      await cubit.load(refresh: true);
      held.complete(_eligibility(repository, status: 'UNKNOWN'));
      await Future<void>.delayed(Duration.zero);
      expect(cubit.state.eligibility!.status, 'SHIFT_ASSIGNMENT_REQUIRED');
      expect(cubit.state.current!.isOpen, isFalse);
    },
  );

  test(
    'duplicate loads share work and repeated refreshes coalesce safely',
    () async {
      final repository = _ControlledRepository();
      final held = Completer<TemplateEligibility>();
      repository.eligibilityReads.add(held);
      repository.eligibilityStarted = Completer<void>();
      final cubit = FlexibleAttendanceCubit(repository)
        ..bindSession(_employeeScope);
      addTearDown(cubit.close);
      final first = cubit.load();
      expect(identical(first, cubit.load()), isTrue);
      await repository.eligibilityStarted!.future;
      expect(identical(first, cubit.load(refresh: true)), isTrue);
      expect(identical(first, cubit.load(refresh: true)), isTrue);
      repository.eligibilityStatus = 'SHIFT_ASSIGNMENT_REQUIRED';
      held.complete(_eligibility(repository, status: 'UNKNOWN'));
      await first;
      expect(cubit.state.eligibility!.status, 'SHIFT_ASSIGNMENT_REQUIRED');
    },
  );

  for (final stage in ['current', 'storage', 'catalog', 'eligibility']) {
    for (final logout in [true, false]) {
      test(
        '$stage response is invalidated by ${logout ? 'logout' : 'workspace switch'}',
        () async {
          final repository = _ControlledRepository()
            ..current = FlexibleAttendance.fromJson(_attendance());
          final current = Completer<FlexibleAttendance?>();
          final storage = Completer<PendingClockIn?>();
          final catalog = Completer<ShiftTemplatePage>();
          final eligibility = Completer<TemplateEligibility>();
          if (stage == 'eligibility') {
            repository.eligibilityReads.add(eligibility);
            repository.eligibilityStarted = Completer<void>();
          }
          if (stage == 'current') {
            repository.currentRead = current;
          }
          if (stage == 'storage') {
            repository.pendingRead = storage;
          }
          if (stage == 'catalog') {
            repository.catalogRead = catalog;
            repository.catalogStarted = Completer<void>();
          }
          final cubit = FlexibleAttendanceCubit(repository)
            ..bindSession(_employeeScope);
          addTearDown(cubit.close);
          final old = cubit.load();
          if (stage == 'eligibility') {
            await repository.eligibilityStarted!.future;
          } else if (stage == 'catalog') {
            await repository.catalogStarted!.future;
          } else if (stage == 'storage') {
            await cubit.stream.firstWhere((s) => s.current != null);
          }
          repository.currentRead = null;
          repository.pendingRead = null;
          repository.catalogRead = null;
          cubit.bindSession(
            logout
                ? null
                : const FeatureSessionScope(
                    userId: 'other-user',
                    workspaceId: 'other-workspace',
                    membershipId: 'other-membership',
                    timezone: 'UTC',
                    role: WorkspaceRole.employee,
                  ),
          );
          if (stage == 'current') {
            current.complete(repository.current);
          }
          if (stage == 'storage') {
            storage.complete(_pending());
          }
          if (stage == 'catalog') {
            catalog.complete(repository.page);
          }
          if (stage == 'eligibility') {
            eligibility.complete(_eligibility(repository));
          }
          await old;
          await cubit.load();
          expect(cubit.state.current, isNull);
          expect(cubit.state.recovery, isNull);
          expect(cubit.state.eligibility, isNull);
        },
      );
    }
  }

  test(
    'clock-out canonical success survives callback and eligibility failure',
    () async {
      final repository = _ControlledRepository()
        ..current = FlexibleAttendance.fromJson(_attendance());
      final cubit = FlexibleAttendanceCubit(
        repository,
        onAttendanceChanged: () {
          repository.refreshFails = true;
          throw StateError('callback failed');
        },
      )..bindSession(_employeeScope);
      addTearDown(cubit.close);
      await cubit.load();
      expect(await cubit.clockOut(), FixedShiftMutationResult.success);
      if (cubit.state.failure == null) {
        await cubit.stream.firstWhere((s) => s.failure != null);
      }
      expect(cubit.state.current!.isOpen, isFalse);
    },
  );

  for (final version in [1, 2]) {
    test(
      'v$version identifiable legacy owner isolates user workspace and membership',
      () async {
        final raw = jsonEncode({
          'userId': _employeeScope.userId,
          'workspaceId': _employeeScope.workspaceId,
          'membershipId': _employeeScope.membershipId,
          'templateId': 'template-id',
          'clientAttendanceId': _pending().clientAttendanceId,
        });
        final key = version == 1
            ? 'fixed_shift.pending_clock_in.v1'
            : 'fixed_shift.pending_clock_in.v2.employee-user.workspace-id.employee-membership-id.template-id';
        SharedPreferences.setMockInitialValues({key: raw});
        final preferences = await SharedPreferences.getInstance();
        final adapter = _Adapter(
          (_) => _json({
            'data': [],
            'pagination': {
              'page': 1,
              'limit': 100,
              'total': 0,
              'totalPages': 0,
            },
          }),
        );
        final repository = ApiFixedShiftRepository(
          Dio()..httpClientAdapter = adapter,
          preferences,
        );
        for (final scope in [
          const FeatureSessionScope(
            userId: 'other',
            workspaceId: 'workspace-id',
            membershipId: 'employee-membership-id',
            timezone: 'UTC',
            role: WorkspaceRole.employee,
          ),
          const FeatureSessionScope(
            userId: 'employee-user',
            workspaceId: 'other',
            membershipId: 'employee-membership-id',
            timezone: 'UTC',
            role: WorkspaceRole.employee,
          ),
          const FeatureSessionScope(
            userId: 'employee-user',
            workspaceId: 'workspace-id',
            membershipId: 'other',
            timezone: 'UTC',
            role: WorkspaceRole.employee,
          ),
        ]) {
          expect(await repository.inspectLegacyClockIns(scope), isEmpty);
        }
        expect(adapter.requests, isEmpty);
        final review = await repository.inspectLegacyClockIns(_employeeScope);
        expect(review.single.requiresReview, isTrue);
        expect(review.single.clientAttendanceId, _pending().clientAttendanceId);
        expect(preferences.getString(key), raw);
        expect(adapter.requests.every((r) => r.method == 'GET'), isTrue);
      },
    );

    test(
      'v$version canonical legacy success reconciles without any POST or deletion',
      () async {
        final raw = jsonEncode({
          'userId': _employeeScope.userId,
          'workspaceId': 'workspace-id',
          'membershipId': _employeeScope.membershipId,
          'templateId': 'template-id',
          'clientAttendanceId': _pending().clientAttendanceId,
        });
        final key = version == 1
            ? 'fixed_shift.pending_clock_in.v1'
            : 'fixed_shift.pending_clock_in.v2.employee-user.workspace-id.employee-membership-id.template-id';
        SharedPreferences.setMockInitialValues({key: raw});
        final preferences = await SharedPreferences.getInstance();
        final adapter = _Adapter(
          (_) => _json(_page(_attendance(clockOutAt: '2026-10-07T03:00:00Z'))),
        );
        final repository = ApiFixedShiftRepository(
          Dio()..httpClientAdapter = adapter,
          preferences,
        );
        final review = (await repository.inspectLegacyClockIns(_employeeScope))
            .single;
        expect(review.requiresReview, isFalse);
        expect(review.canonical!.id, 'attendance-id');
        expect(review.canonical!.isOpen, isFalse);
        expect(adapter.requests.single.method, 'GET');
        expect(preferences.getString(key), raw);
        expect(
          await repository.loadPendingClockIn(
            userId: _employeeScope.userId,
            workspaceId: 'workspace-id',
            membershipId: _employeeScope.membershipId,
            templateId: '',
          ),
          isNull,
        );
      },
    );
  }

  test(
    'ambiguous legacy review stays explicit while v3 recovery remains exact',
    () async {
      final client = await _client((_) => _json(null));
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(
        'fixed_shift.pending_clock_in.v1',
        '{unidentifiable}',
      );
      await client.repository.savePendingClockIn(_pending());
      final review = (await client.repository.inspectLegacyClockIns(
        _employeeScope,
      )).single;
      expect(review.requiresReview, isTrue);
      expect(review.message, contains('Contact support'));
      final active = await client.repository.loadPendingClockIn(
        userId: _employeeScope.userId,
        workspaceId: 'workspace-id',
        membershipId: _employeeScope.membershipId,
        templateId: '',
      );
      expect(active!.clientAttendanceId, _pending().clientAttendanceId);
      expect(active.payload, _pending().payload);
      await client.repository.clearPendingClockIn(active);
      expect(
        preferences.getString('fixed_shift.pending_clock_in.v1'),
        '{unidentifiable}',
      );
      expect(client.adapter.requests, isEmpty);
    },
  );

  test('failed legacy reconciliation preserves the original evidence and review state', () async {
    final raw = jsonEncode({
      'userId': _employeeScope.userId,
      'workspaceId': 'workspace-id',
      'membershipId': _employeeScope.membershipId,
      'templateId': 'template-id',
      'clientAttendanceId': _pending().clientAttendanceId,
    });
    SharedPreferences.setMockInitialValues({
      'fixed_shift.pending_clock_in.v1': raw,
    });
    final preferences = await SharedPreferences.getInstance();
    final adapter = _Adapter((_) => _json({'message': 'offline'}, status: 503));
    final repository = ApiFixedShiftRepository(
      Dio()..httpClientAdapter = adapter,
      preferences,
    );
    final review = (await repository.inspectLegacyClockIns(_employeeScope))
        .single;
    expect(review.requiresReview, isTrue);
    expect(review.message, contains('restore access'));
    expect(preferences.getString('fixed_shift.pending_clock_in.v1'), raw);
    expect(adapter.requests.single.method, 'GET');
  });

  test('held extra callback serializes create recovery and revoke through follow-up reads', () async {
    final callback = Completer<void>(), started = Completer<void>();
    final repository = _ExtraRepository();
    final cubit = ExtraShiftsCubit(
      repository,
      onChanged: () {
        started.complete();
        return callback.future;
      },
    )..bind(_managerScope, 'membership-id');
    addTearDown(cubit.close);
    await cubit.load();
    final first = cubit.create(_extraPayload(), actual: false);
    await started.future;
    expect(cubit.state.busy, isTrue);
    expect(await cubit.create(_extraPayload(), actual: false), isFalse);
    expect(await cubit.recover(), isFalse);
    expect(await cubit.revoke(cubit.state.canonical!), isFalse);
    expect(repository.requests, hasLength(1));
    expect(repository.revocations, 0);
    callback.complete();
    expect(await first, isTrue);
    expect(cubit.state.busy, isFalse);
  });

  test('old extra finally cannot unlock a newer generation mutation', () async {
    final callback = Completer<void>(), started = Completer<void>();
    var calls = 0;
    final repository = _ExtraRepository();
    final cubit = ExtraShiftsCubit(
      repository,
      onChanged: () {
        if (++calls == 1) {
          started.complete();
          return callback.future;
        }
      },
    )..bind(_managerScope, 'membership-id');
    addTearDown(cubit.close);
    await cubit.load();
    final old = cubit.create(_extraPayload(), actual: false);
    await started.future;
    cubit.bind(null, 'membership-id');
    cubit.bind(_managerScope, 'membership-id');
    await cubit.load();
    repository.completer = Completer<ExtraAuthorization>();
    repository.submissionStarted = Completer<void>();
    final newer = cubit.create(_extraPayload(), actual: false);
    await repository.submissionStarted!.future;
    callback.complete();
    expect(await old, isTrue);
    expect(cubit.state.busy, isTrue);
    expect(await cubit.create(_extraPayload(), actual: false), isFalse);
    expect(await cubit.recover(), isFalse);
    repository.completer!.complete(
      ExtraAuthorization(_extraJson(repository.requests.last)),
    );
    expect(await newer, isTrue);
    expect(repository.requests, hasLength(2));
  });

  test(
    'old extra list response cannot replace newer uncertain intent',
    () async {
      final repository = _ExtraRepository();
      final cubit = ExtraShiftsCubit(repository)
        ..bind(_managerScope, 'membership-id');
      addTearDown(cubit.close);
      await cubit.load();
      repository.listRead = Completer<ExtraAuthorizationPage>();
      repository.listStarted = Completer<void>();
      final held = repository.listRead!;
      final old = cubit.load();
      await repository.listStarted!.future;
      cubit.bind(null, 'membership-id');
      repository.listRead = null;
      cubit.bind(_managerScope, 'membership-id');
      await cubit.load();
      repository.uncertain = true;
      expect(await cubit.create(_extraPayload(), actual: false), isFalse);
      final intent = cubit.state.intent;
      held.complete(
        const ExtraAuthorizationPage(
          [],
          ApiPagination(page: 1, limit: 20, total: 0, totalPages: 0),
        ),
      );
      await old;
      expect(cubit.state.intent, intent);
      expect(cubit.state.recoveryBlocked, isTrue);
      expect(repository.stored, intent!.encode());
    },
  );

  test('extra canonical success survives callback failure and retains recovery target', () async {
    final repository = _ExtraRepository()..uncertain = true;
    final cubit = ExtraShiftsCubit(
      repository,
      onChanged: () {
        repository.refreshFails = true;
        throw StateError('callback failed');
      },
    )..bind(_managerScope, 'membership-id');
    addTearDown(cubit.close);
    await cubit.load();
    expect(await cubit.create(_extraPayload(), actual: false), isFalse);
    cubit.bind(_managerScope, 'different-employee');
    await cubit.load();
    expect(cubit.state.intent!.membershipId, 'membership-id');
    repository.uncertain = false;
    expect(await cubit.recover(), isTrue);
    expect(repository.requests.first, repository.requests.last);
    expect(
      cubit.state.canonical!.fields['employeeMembershipId'],
      'membership-id',
    );
    expect(cubit.state.failure, isNotNull);
    expect(cubit.state.busy, isFalse);
  });

  for (final switchKind in ['employee', 'workspace', 'user']) {
    test('extra $switchKind switch rejects pending canonical result', () async {
      final repository = _ExtraRepository()
        ..completer = Completer<ExtraAuthorization>();
      final cubit = ExtraShiftsCubit(repository)
        ..bind(_managerScope, 'membership-id');
      addTearDown(cubit.close);
      await cubit.load();
      repository.submissionStarted = Completer<void>();
      final first = cubit.create(_extraPayload(), actual: false);
      await repository.submissionStarted!.future;
      final scope = switchKind == 'employee'
          ? _managerScope
          : FeatureSessionScope(
              userId: switchKind == 'user'
                  ? 'other-user'
                  : _managerScope.userId,
              workspaceId: switchKind == 'workspace'
                  ? 'other-workspace'
                  : _managerScope.workspaceId,
              membershipId: _managerScope.membershipId,
              timezone: 'UTC',
              role: WorkspaceRole.manager,
            );
      cubit.bind(
        scope,
        switchKind == 'employee' ? 'other-employee' : 'membership-id',
      );
      repository.completer!.complete(
        ExtraAuthorization(_extraJson(repository.requests.first)),
      );
      expect(await first, isFalse);
      expect(cubit.state.canonical, isNull);
      expect(repository.stored, isNotNull);
    });
  }
}

Map<String, Object?> _savedSchedule() => {
  'id': 'template-id',
  'name': 'Saved night schedule',
  'color': '#334155',
  'timezone': 'Africa/Cairo',
  'conversionPolicy': 'POSTGRES_V1',
  'startMinute': 1320,
  'endMinute': 360,
  'graceMinutes': 10,
  'allowedEarlyCheckInMinutes': 30,
  'allowedLateCheckInMinutes': 120,
  'minimumWorkMinutes': 420,
};
Map<String, Object?> _occurrenceJson({
  String kind = 'BASELINE',
  bool used = false,
  bool eligible = true,
}) => {
  'template': {
    ..._template(),
    'timezone': 'Africa/Cairo',
    'conversionPolicy': 'POSTGRES_V1',
  },
  'occurrenceKind': kind,
  'assignmentId': kind == 'BASELINE' ? 'assignment-id' : null,
  'extraAuthorizationId': kind == 'EXTRA' ? 'extra-id' : null,
  'operationalDate': '2026-10-06',
  'scheduledStartAt': '2026-10-06T19:00:00Z',
  'scheduledEndAt': '2026-10-07T03:00:00Z',
  'checkInWindowStart': '2026-10-06T18:30:00Z',
  'checkInWindowEnd': '2026-10-06T21:00:00Z',
  'expectedClockInClassification': 'ON_TIME',
  'lateMinutes': 0,
  'recommended': true,
  'eligible': eligible && !used,
  'alreadyUsed': used,
};
Map<String, Object?> _extraJson(
  Map<String, Object?> payload, {
  String status = 'AUTHORIZED',
}) => {
  ...payload,
  'id': 'extra-id',
  'workspaceId': 'workspace-id',
  'employeeMembershipId': 'membership-id',
  'status': status,
  'createdByMembershipId': _managerScope.membershipId,
  'createdAt': '2026-10-06T12:00:00Z',
  'occurrenceSnapshot': _savedSchedule(),
  'consumedAt': status == 'CONSUMED' ? '2026-10-06T23:00:00Z' : null,
  'revokedAt': status == 'REVOKED' ? '2026-10-06T13:00:00Z' : null,
  'revokedByMembershipId': status == 'REVOKED'
      ? _managerScope.membershipId
      : null,
  'attendance': status == 'CONSUMED'
      ? [
          {
            ..._attendance(clockOutAt: payload['actualClockOutAt'] as String?),
            'occurrenceKind': 'EXTRA',
            'assignmentId': null,
            'extraAuthorizationId': 'extra-id',
            'enteredByMembershipId': _managerScope.membershipId,
            'reviewStatus': 'APPROVED',
          },
        ]
      : [],
};
Map<String, Object?> _extraPayload() => {
  'shiftTemplateId': 'template-id',
  'operationalDate': '2026-10-06',
  'reason': 'ADDITIONAL_SHIFT',
  'explanation': 'Evening inventory coverage',
};

class _ControlledRepository extends _FakeRepository {
  String kind = 'BASELINE', eligibilityStatus = 'ASSIGNED';
  bool used = false, uncertain = false, lookupFails = false;
  FlexibleAttendance? current, saved;
  Completer<FlexibleAttendance>? clockInCompleter;
  final payloads = <Map<String, Object?>>[];
  Completer<FlexibleAttendance?>? currentRead;
  Completer<PendingClockIn?>? pendingRead;
  Completer<ShiftTemplatePage>? catalogRead;
  Completer<void>? catalogStarted;
  final eligibilityReads = <Completer<TemplateEligibility>>[];
  Completer<void>? eligibilityStarted;
  @override
  Future<ShiftTemplatePage> listMyTemplates(
    String workspaceId, {
    int page = 1,
    int limit = 100,
  }) {
    if (catalogStarted?.isCompleted == false) {
      catalogStarted!.complete();
    }
    return catalogRead?.future ??
        super.listMyTemplates(workspaceId, page: page, limit: limit);
  }

  @override
  Future<PendingClockIn?> loadPendingClockIn({
    required String userId,
    required String workspaceId,
    required String membershipId,
    required String templateId,
  }) =>
      pendingRead?.future ??
      super.loadPendingClockIn(
        userId: userId,
        workspaceId: workspaceId,
        membershipId: membershipId,
        templateId: templateId,
      );

  @override
  EligibleShiftOccurrence get occurrence =>
      EligibleShiftOccurrence.fromJson(_occurrenceJson(kind: kind, used: used));
  @override
  Future<TemplateEligibility> getEligibility(String workspaceId) async {
    if (eligibilityReads.isNotEmpty) {
      final response = eligibilityReads.removeAt(0);
      if (eligibilityStarted?.isCompleted == false) {
        eligibilityStarted!.complete();
      }
      return response.future;
    }
    if (refreshFails) {
      throw const ApiException(message: 'offline', kind: FailureKind.network);
    }
    return TemplateEligibility(
      workspaceId: workspaceId,
      timezone: 'Africa/Cairo',
      evaluatedAt: DateTime.utc(2026, 10, 6, 19),
      status: eligibilityStatus,
      recommended: occurrence.canClockIn ? occurrence : null,
      eligibleTemplates: occurrence.canClockIn ? [occurrence] : [],
      authorizedOccurrences: [occurrence],
    );
  }

  @override
  Future<FlexibleAttendance?> getCurrentAttendance(String workspaceId) =>
      currentRead?.future ?? Future.value(current);
  @override
  Future<FlexibleAttendance?> findPendingAttendance(
    PendingClockIn value,
  ) async {
    if (lookupFails) {
      throw const ApiException(message: 'offline', kind: FailureKind.network);
    }
    return saved;
  }

  @override
  Future<FlexibleAttendance> flexibleClockIn({
    required String workspaceId,
    required String shiftTemplateId,
    required String clientAttendanceId,
    String? assignmentId,
    String? extraAuthorizationId,
  }) async {
    payloads.add({
      'workspaceId': workspaceId,
      'shiftTemplateId': shiftTemplateId,
      'clientAttendanceId': clientAttendanceId,
      'assignmentId': ?assignmentId,
      'extraAuthorizationId': ?extraAuthorizationId,
    });
    if (clockInCompleter != null) {
      return clockInCompleter!.future;
    }
    final canonical = FlexibleAttendance.fromJson({
      ..._attendance(),
      'clientAttendanceId': clientAttendanceId,
      'occurrenceKind': kind,
      'assignmentId': assignmentId,
      'extraAuthorizationId': extraAuthorizationId,
    });
    if (uncertain) {
      throw const ApiException(message: 'timeout', kind: FailureKind.timeout);
    }
    used = true;
    current = canonical;
    saved = canonical;
    return canonical;
  }

  @override
  Future<FlexibleAttendance> flexibleClockOut(String attendanceId) async {
    final canonical = FlexibleAttendance.fromJson({
      ..._attendance(clockOutAt: '2026-10-06T20:00:00Z'),
      'occurrenceKind': kind,
      'assignmentId': kind == 'BASELINE' ? 'assignment-id' : null,
      'extraAuthorizationId': kind == 'EXTRA' ? 'extra-id' : null,
    });
    current = null;
    saved = canonical;
    used = true;
    return canonical;
  }
}

class _ExtraRepository implements ExtraShiftRepository {
  String? stored;
  bool uncertain = false, refreshFails = false, reject = false;
  Completer<ExtraAuthorization>? completer;
  Completer<void>? submissionStarted;
  Completer<ExtraAuthorizationPage>? listRead;
  Completer<void>? listStarted;
  int revocations = 0;
  final requests = <Map<String, Object?>>[];
  final canonical = <String, ExtraAuthorization>{};
  @override
  Future<String?> readExtraIntent(FeatureSessionScope scope) async => stored;
  @override
  Future<void> saveExtraIntent(FeatureSessionScope scope, String intent) async {
    if (stored != null && stored != intent) {
      throw StateError('Conflicting recovery');
    }
    stored = intent;
  }

  @override
  Future<void> clearExtraIntent(
    FeatureSessionScope scope,
    String intent,
  ) async {
    if (stored == intent) {
      stored = null;
    }
  }

  @override
  Future<ExtraAuthorizationPage> listExtras(
    String workspaceId,
    String membershipId, {
    int page = 1,
    int limit = 20,
  }) async {
    if (listRead != null) {
      if (listStarted?.isCompleted == false) {
        listStarted!.complete();
      }
      return listRead!.future;
    }
    if (refreshFails) {
      throw const ApiException(message: 'offline', kind: FailureKind.network);
    }
    return ExtraAuthorizationPage(
      canonical.values.toList(),
      const ApiPagination(page: 1, limit: 20, total: 0, totalPages: 0),
    );
  }

  @override
  Future<ExtraAuthorization> createExtra(
    String workspaceId,
    String membershipId,
    Map<String, Object?> payload, {
    required bool actual,
  }) async {
    requests.add(Map.from(payload));
    if (submissionStarted?.isCompleted == false) {
      submissionStarted!.complete();
    }
    expect(
      stored,
      isNotNull,
      reason: 'intent must be durable before HTTP submission',
    );
    if (reject) {
      throw const ApiException(
        message: 'Overlap',
        code: 'EXTRA_SCHEDULE_OVERLAP',
        statusCode: 409,
      );
    }
    if (completer != null) {
      return completer!.future;
    }
    final key = payload['clientAuthorizationId'] as String;
    final saved = canonical.putIfAbsent(
      key,
      () => ExtraAuthorization(
        _extraJson(payload, status: actual ? 'CONSUMED' : 'AUTHORIZED'),
      ),
    );
    if (uncertain) {
      throw const ApiException(message: 'timeout', kind: FailureKind.timeout);
    }
    return saved;
  }

  @override
  Future<ExtraAuthorization> revokeExtra(
    String workspaceId,
    String membershipId,
    String authorizationId,
  ) async {
    revocations++;
    return ExtraAuthorization(
      _extraJson({
        ..._extraPayload(),
        'clientAuthorizationId': '11111111-1111-4111-8111-111111111111',
      }, status: 'REVOKED'),
    );
  }
}

class _AssignmentRepository extends _FakeRepository {
  bool reject = false, failRefresh = false;
  WorkPattern? value;
  int mutations = 0;
  @override
  Future<WorkPatternHistory> getWorkPatterns(
    String workspaceId,
    String membershipId, {
    int page = 1,
    int limit = 20,
  }) async {
    if (failRefresh && value != null) {
      throw const ApiException(message: 'offline', kind: FailureKind.network);
    }
    return WorkPatternHistory(
      current: null,
      history: value == null ? [] : [value!],
    );
  }

  @override
  Future<WorkPattern> replaceWorkPattern(
    String workspaceId,
    String membershipId, {
    required String shiftTemplateId,
    required List<int> expectedWeekdays,
    required String effectiveFrom,
  }) async {
    mutations++;
    if (reject) {
      throw const ApiException(
        message: 'Captured occurrence',
        code: 'ASSIGNMENT_OCCURRENCE_CAPTURED',
        statusCode: 409,
      );
    }
    value = WorkPattern.fromJson({
      'id': 'new-assignment',
      'workspaceId': workspaceId,
      'employeeMembershipId': membershipId,
      'shiftTemplateId': shiftTemplateId,
      'assignmentSnapshot': _savedSchedule(),
      'expectedWeekdays': expectedWeekdays,
      'effectiveFrom': effectiveFrom,
      'effectiveTo': null,
      'createdAt': '2026-10-06T00:00:00Z',
      'updatedAt': '2026-10-06T00:00:00Z',
    });
    return value!;
  }
}

void assignedSprintTests() {
  test(
    'shared attendance history retains nullable occurrence linkage and audit',
    () {
      final json = {
        ..._attendance(),
        'employee': {
          'id': 'employee-membership-id',
          'profileId': 'profile-id',
          'role': 'EMPLOYEE',
          'status': 'ACTIVE',
        },
      };
      final baseline = AttendanceRecordApi.fromJson(json);
      expect(baseline.assignmentId, 'assignment-id');
      final extra = AttendanceRecordApi.fromJson({
        ...json,
        'occurrenceKind': 'EXTRA',
        'assignmentId': null,
        'extraAuthorizationId': 'extra-id',
        'enteredByMembershipId': 'manager-membership',
      });
      expect(extra.assignmentId, isNull);
      expect(extra.extraAuthorizationId, 'extra-id');
      expect(extra.enteredByMembershipId, 'manager-membership');
      final old = AttendanceRecordApi.fromJson({
        ...json,
        'occurrenceKind': null,
        'assignmentId': null,
      });
      expect(old.occurrenceKind, isNull);
      expect(old.assignmentId, isNull);
      expect(old.scheduledStartAt, baseline.scheduledStartAt);
    },
  );

  test('unupgraded eligibility cannot grant employee clock-in', () async {
    final repository = _ControlledRepository()..eligibilityStatus = 'UNKNOWN';
    final cubit = FlexibleAttendanceCubit(repository)
      ..bindSession(_employeeScope);
    addTearDown(cubit.close);
    await cubit.stream.firstWhere((state) => !state.loading);
    expect(
      await cubit.clockIn(repository.occurrence),
      FixedShiftMutationResult.failure,
    );
    expect(repository.payloads, isEmpty);
  });
  test('an uncertain baseline never becomes an extra retry', () async {
    final repository = _ControlledRepository()..uncertain = true;
    final cubit = FlexibleAttendanceCubit(repository)
      ..bindSession(_employeeScope);
    addTearDown(cubit.close);
    await cubit.stream.firstWhere((state) => !state.loading);
    await cubit.clockIn(repository.occurrence);
    final original = repository.pending;
    repository.kind = 'EXTRA';
    expect(
      await cubit.clockIn(repository.occurrence),
      FixedShiftMutationResult.failure,
    );
    expect(repository.pending, same(original));
    expect(repository.payloads, hasLength(1));
    expect(
      repository.payloads.first.containsKey('extraAuthorizationId'),
      isFalse,
    );
  });
  test(
    'business errors preserve safe metadata without provider diagnostics',
    () async {
      final client = await _client(
        (_) => _json({
          'statusCode': 409,
          'code': 'EXTRA_SCHEDULE_OVERLAP',
          'message': 'private database constraint text',
          'requestId': 'request-safe',
        }, status: 409),
      );
      try {
        await client.repository.createExtra(
          'workspace-id',
          'membership-id',
          _extraPayload(),
          actual: false,
        );
        fail('Expected safe conflict');
      } on ApiException catch (error) {
        expect(error.code, 'EXTRA_SCHEDULE_OVERLAP');
        expect(error.statusCode, 409);
        expect(error.requestId, 'request-safe');
        expect(error.message, isNot(contains('database')));
        expect(error.toFailure().code, error.code);
        expect(error.toFailure().statusCode, 409);
      }
    },
  );

  test(
    'defensive occurrence models deny missing IDs, enums, policies and usage',
    () {
      for (final patch in <Map<String, Object?>>[
        {'occurrenceKind': 'UNKNOWN'},
        {'assignmentId': null},
        {'alreadyUsed': true},
        {'eligible': false},
        {'expectedClockInClassification': 'UNKNOWN'},
        {
          'template': {..._template(), 'conversionPolicy': 'FUTURE_V2'},
        },
        {'template': _template(active: false)},
        {'alreadyUsed': null},
      ]) {
        expect(
          EligibleShiftOccurrence.fromJson({..._occurrenceJson(), ...patch})
              .canClockIn,
          isFalse,
        );
      }
      expect(
        EligibleShiftOccurrence.fromJson(_occurrenceJson(kind: 'EXTRA'))
            .canClockIn,
        isTrue,
      );
      final legacy = WorkPattern.fromJson(const {
        'id': 'old',
        'workspaceId': 'workspace-id',
        'employeeMembershipId': 'membership-id',
        'expectedWeekdays': [1],
        'effectiveFrom': '2026-01-01',
        'createdAt': '2026-01-01T00:00:00Z',
        'updatedAt': '2026-01-01T00:00:00Z',
      });
      expect(legacy.assignmentSnapshot, isNull);
      expect(legacy.shiftTemplateId, isNull);
    },
  );
  test(
    'baseline and extra HTTP payloads contain only their canonical linkage',
    () async {
      final client = await _client((_) => _json(_attendance(), status: 201));
      await client.repository.flexibleClockIn(
        workspaceId: 'workspace-id',
        shiftTemplateId: 'template-id',
        clientAttendanceId: 'key',
        assignmentId: 'assignment-id',
      );
      await client.repository.flexibleClockIn(
        workspaceId: 'workspace-id',
        shiftTemplateId: 'template-id',
        clientAttendanceId: 'key-2',
        extraAuthorizationId: 'extra-id',
      );
      expect(client.adapter.requests.first.data, {
        'workspaceId': 'workspace-id',
        'shiftTemplateId': 'template-id',
        'clientAttendanceId': 'key',
        'assignmentId': 'assignment-id',
      });
      expect(client.adapter.requests.last.data, {
        'workspaceId': 'workspace-id',
        'shiftTemplateId': 'template-id',
        'clientAttendanceId': 'key-2',
        'extraAuthorizationId': 'extra-id',
      });
    },
  );
  test(
    'manager extras use exact pagination, paths, verbs and canonical response',
    () async {
      final payload = {
        ..._extraPayload(),
        'clientAuthorizationId': '11111111-1111-4111-8111-111111111111',
      };
      final client = await _client((options) {
        if (options.method == 'GET') {
          return _json(_page(_extraJson(payload)..remove('attendance')));
        }
        return _json(
          _extraJson(
            options.method == 'DELETE'
                ? payload
                : Map<String, Object?>.from(options.data as Map),
            status: options.method == 'DELETE'
                ? 'REVOKED'
                : options.path.endsWith('/attendance')
                ? 'CONSUMED'
                : 'AUTHORIZED',
          ),
        );
      });
      await client.repository.listExtras(
        'workspace-id',
        'membership-id',
        page: 2,
        limit: 20,
      );
      final created = await client.repository.createExtra(
        'workspace-id',
        'membership-id',
        payload,
        actual: false,
      );
      await client.repository.revokeExtra(
        'workspace-id',
        'membership-id',
        created.id,
      );
      final actual = {
        ...payload,
        'actualClockInAt': '2026-10-06T19:00:00Z',
        'actualClockOutAt': '2026-10-06T23:00:00Z',
      };
      final saved = await client.repository.createExtra(
        'workspace-id',
        'membership-id',
        actual,
        actual: true,
      );
      expect(client.adapter.requests.first.queryParameters, {
        'page': 2,
        'limit': 20,
      });
      expect(
        client.adapter.requests[1].path,
        '/workspaces/workspace-id/employees/membership-id/extra-shifts',
      );
      expect(client.adapter.requests[1].data, payload);
      expect(client.adapter.requests[2].method, 'DELETE');
      expect(client.adapter.requests[2].data, isNull);
      expect(
        client.adapter.requests.last.path,
        '/workspaces/workspace-id/employees/membership-id/extra-shifts/attendance',
      );
      expect(client.adapter.requests.last.data, actual);
      expect(saved.status, 'CONSUMED');
      expect(saved.schedule.name, 'Saved night schedule');
    },
  );
  test('legacy stored clock-in is quarantined without deletion or replay', () async {
    SharedPreferences.setMockInitialValues({
      'fixed_shift.pending_clock_in.v1': '{old-operation}',
      'fixed_shift.pending_clock_in.v2.user-a.workspace-a.membership-a.template-a':
          '{old-scoped-operation}',
    });
    final preferences = await SharedPreferences.getInstance();
    final repository = ApiFixedShiftRepository(Dio(), preferences);
    expect(
      await repository.loadPendingClockIn(
        userId: 'user-a',
        workspaceId: 'workspace-a',
        membershipId: 'membership-a',
        templateId: 'template-a',
      ),
      isNull,
    );
    final reviews = await repository.inspectLegacyClockIns(
      const FeatureSessionScope(
        userId: 'user-a',
        workspaceId: 'workspace-a',
        membershipId: 'membership-a',
        timezone: 'UTC',
        role: WorkspaceRole.employee,
      ),
    );
    expect(reviews, hasLength(2));
    expect(reviews.every((v) => v.requiresReview), isTrue);
    expect(
      preferences.getString('fixed_shift.pending_clock_in.v1'),
      '{old-operation}',
    );
    expect(preferences.getKeys(), hasLength(2));
  });
  test(
    'durable extras cannot overwrite another intent and are scope isolated',
    () async {
      final client = await _client((_) => _json(null));
      await client.repository.saveExtraIntent(_managerScope, 'first');
      await expectLater(
        client.repository.saveExtraIntent(_managerScope, 'second'),
        throwsStateError,
      );
      const other = FeatureSessionScope(
        userId: 'another',
        workspaceId: 'workspace-id',
        membershipId: 'manager-membership',
        timezone: 'UTC',
        role: WorkspaceRole.manager,
      );
      expect(await client.repository.readExtraIntent(other), isNull);
      await client.repository.clearExtraIntent(_managerScope, 'second');
      expect(await client.repository.readExtraIntent(_managerScope), 'first');
    },
  );
  for (final kind in ['BASELINE', 'EXTRA']) {
    test('$kind early clock-out leaves occurrence consumed', () async {
      final repository = _ControlledRepository()..kind = kind;
      final cubit = FlexibleAttendanceCubit(repository)
        ..bindSession(_employeeScope);
      addTearDown(cubit.close);
      await cubit.stream.firstWhere((s) => !s.loading);
      final original = repository.occurrence;
      expect(await cubit.clockIn(original), FixedShiftMutationResult.success);
      expect(await cubit.clockOut(), FixedShiftMutationResult.success);
      expect(await cubit.clockIn(original), FixedShiftMutationResult.failure);
      expect(repository.payloads, hasLength(1));
      expect(cubit.state.current?.clockOutAt, isNotNull);
    });
  }
  test('rejected occurrence remains used after refresh', () async {
    final repository = _ControlledRepository()..used = true;
    repository.saved = FlexibleAttendance.fromJson({
      ..._attendance(),
      'reviewStatus': 'REJECTED',
    });
    final cubit = FlexibleAttendanceCubit(repository)
      ..bindSession(_employeeScope);
    addTearDown(cubit.close);
    await cubit.stream.firstWhere((s) => !s.loading);
    expect(repository.saved!.isOpen, isFalse);
    expect(
      await cubit.clockIn(repository.occurrence),
      FixedShiftMutationResult.failure,
    );
    expect(repository.payloads, isEmpty);
  });
  test(
    'duplicate taps and stale employee responses never update switched state',
    () async {
      final repository = _ControlledRepository()
        ..clockInCompleter = Completer<FlexibleAttendance>();
      final cubit = FlexibleAttendanceCubit(repository)
        ..bindSession(_employeeScope);
      addTearDown(cubit.close);
      await cubit.stream.firstWhere((s) => !s.loading);
      final first = cubit.clockIn(repository.occurrence);
      expect(
        await cubit.clockIn(repository.occurrence),
        FixedShiftMutationResult.busy,
      );
      await Future<void>.delayed(Duration.zero);
      expect(repository.payloads, hasLength(1));
      cubit.bindSession(null);
      repository.clockInCompleter!.complete(repository.attendance());
      expect(await first, FixedShiftMutationResult.stale);
      expect(cubit.state.current, isNull);
      expect(repository.pending, isNotNull);
    },
  );
  test(
    'expired baseline recovery cannot submit against a later occurrence',
    () async {
      final repository = _ControlledRepository()..uncertain = true;
      final cubit = FlexibleAttendanceCubit(
        repository,
        now: () => DateTime.utc(2026, 10, 9),
      )..bindSession(_employeeScope);
      addTearDown(cubit.close);
      await cubit.stream.firstWhere((s) => !s.loading);
      await cubit.clockIn(repository.occurrence);
      expect(await cubit.recoverClockIn(), FixedShiftMutationResult.failure);
      expect(repository.payloads, hasLength(1));
      expect(repository.pending, isNotNull);
      expect(cubit.state.recoveryBlocked, isTrue);
    },
  );
  test(
    'restart recovery resolves a closed canonical attendance without POST',
    () async {
      final repository = _ControlledRepository()..uncertain = true;
      final first = FlexibleAttendanceCubit(repository)
        ..bindSession(_employeeScope);
      await first.stream.firstWhere((s) => !s.loading);
      await first.clockIn(repository.occurrence);
      repository.saved = FlexibleAttendance.fromJson({
        ..._attendance(clockOutAt: '2026-10-06T20:00:00Z'),
        'clientAttendanceId': repository.pending!.clientAttendanceId,
      });
      await first.close();
      final restored = FlexibleAttendanceCubit(repository)
        ..bindSession(_employeeScope);
      addTearDown(restored.close);
      await restored.stream.firstWhere((s) => !s.loading);
      expect(restored.state.recovery, isNotNull);
      expect(await restored.recoverClockIn(), FixedShiftMutationResult.success);
      expect(repository.payloads, hasLength(1));
      expect(restored.state.current?.clockOutAt, isNotNull);
      expect(repository.pending, isNull);
    },
  );
  test(
    'canonical clock-in success survives a failed follow-up refresh',
    () async {
      final repository = _ControlledRepository();
      final cubit = FlexibleAttendanceCubit(
        repository,
        onAttendanceChanged: () {
          repository.refreshFails = true;
        },
      )..bindSession(_employeeScope);
      addTearDown(cubit.close);
      await cubit.stream.firstWhere((s) => !s.loading);
      expect(
        await cubit.clockIn(repository.occurrence),
        FixedShiftMutationResult.success,
      );
      await Future<void>.delayed(Duration.zero);
      expect(cubit.state.current, isNotNull);
      expect(cubit.state.recoveryBlocked, isTrue);
      expect(repository.pending, isNull);
    },
  );
  test(
    'manager extra restart recovery preserves UUID and normalized payload',
    () async {
      final repository = _ExtraRepository()..uncertain = true;
      final first = ExtraShiftsCubit(repository)
        ..bind(_managerScope, 'membership-id');
      await first.stream.firstWhere((s) => !s.loading);
      expect(
        await first.create({
          ..._extraPayload(),
          'explanation': '  Evening   coverage  ',
        }, actual: false),
        isFalse,
      );
      final intent = repository.stored;
      expect(intent, isNotNull);
      await first.close();
      repository.uncertain = false;
      final restored = ExtraShiftsCubit(repository)
        ..bind(_managerScope, 'membership-id');
      addTearDown(restored.close);
      await restored.stream.firstWhere((s) => !s.loading);
      expect(await restored.create(_extraPayload(), actual: true), isFalse);
      expect(await restored.recover(), isTrue);
      expect(repository.requests[0], repository.requests[1]);
      expect(repository.requests.first['explanation'], 'Evening coverage');
      expect(repository.stored, isNull);
      expect(repository.canonical, hasLength(1));
    },
  );
  test('manager entry and revocation retain canonical response after refresh failure', () async {
    final repository = _ExtraRepository();
    final cubit = ExtraShiftsCubit(
      repository,
      onChanged: () {
        repository.refreshFails = true;
      },
    )..bind(_managerScope, 'membership-id');
    addTearDown(cubit.close);
    await cubit.stream.firstWhere((s) => !s.loading);
    expect(
      await cubit.create({
        ..._extraPayload(),
        'actualClockInAt': '2026-10-06T19:00:00Z',
        'actualClockOutAt': '2026-10-06T23:00:00Z',
      }, actual: true),
      isTrue,
    );
    expect(cubit.state.canonical?.status, 'CONSUMED');
    expect(cubit.state.failure, isNotNull);
    expect(await cubit.revoke(cubit.state.canonical!), isFalse);
  });
  test('manager-only extras block duplicate submissions and reject stale responses', () async {
    final repository = _ExtraRepository()
      ..completer = Completer<ExtraAuthorization>();
    final cubit = ExtraShiftsCubit(repository)
      ..bind(_employeeScope, 'membership-id');
    expect(await cubit.create(_extraPayload(), actual: false), isFalse);
    expect(repository.requests, isEmpty);
    cubit.bind(_managerScope, 'membership-id');
    await cubit.stream.firstWhere((s) => !s.loading);
    final first = cubit.create(_extraPayload(), actual: false);
    expect(await cubit.create(_extraPayload(), actual: false), isFalse);
    await Future<void>.delayed(Duration.zero);
    cubit.bind(null, 'membership-id');
    repository.completer!.complete(
      ExtraAuthorization(_extraJson(repository.requests.first)),
    );
    expect(await first, isFalse);
    expect(cubit.state.canonical, isNull);
    expect(repository.stored, isNotNull);
    await cubit.close();
  });
  test(
    'future assignment retains saved schedule and success on refresh failure',
    () async {
      final repository = _AssignmentRepository()..failRefresh = true;
      final cubit = WorkPatternCubit(repository);
      addTearDown(cubit.close);
      await cubit.bind(
        workspaceId: 'workspace-id',
        membershipId: 'membership-id',
        scope: _managerScope,
      );
      expect(
        await cubit.replace(
          shiftTemplateId: 'template-id',
          weekdays: {1, 3},
          effectiveFrom: '2099-10-10',
        ),
        FixedShiftMutationResult.success,
      );
      expect(
        cubit.state.history?.history.first.assignmentSnapshot?.name,
        'Saved night schedule',
      );
      expect(cubit.state.history?.current, isNull);
      expect(cubit.state.failure, isNotNull);
    },
  );
  test(
    'actual timestamp input handles timezone offsets, overnight and DST',
    () {
      expect(
        WorkspaceTimestampInput.parse(
          '2026-10-06T22:00:00+03:00',
          'Africa/Cairo',
        ),
        DateTime.utc(2026, 10, 6, 19),
      );
      expect(
        WorkspaceTimestampInput.parse(
          '2026-11-01T01:30:00-04:00',
          'America/New_York',
        ),
        DateTime.utc(2026, 11, 1, 5, 30),
      );
      expect(
        WorkspaceTimestampInput.parse(
          '2026-11-01T01:30:00-05:00',
          'America/New_York',
        ),
        DateTime.utc(2026, 11, 1, 6, 30),
      );
      for (final input in [
        '2026-03-08T02:30:00-05:00',
        '2026-03-08T02:30:00-04:00',
        '2026-02-30T12:00:00-05:00',
        '2026-10-06T22:00:00',
      ]) {
        expect(
          () => WorkspaceTimestampInput.parse(input, 'America/New_York'),
          throwsFormatException,
        );
      }
      expect(
        () => WorkspaceTimestampInput.parse(
          '2026-10-06T22:00:00+02:00',
          'Africa/Cairo',
        ),
        throwsFormatException,
      );
      expect(
        () => WorkspaceTimestampInput.validateRange(
          DateTime.utc(2026, 10, 6, 23),
          DateTime.utc(2026, 10, 7, 3),
          DateTime.utc(2026, 10, 7, 4),
        ),
        returnsNormally,
      );
      expect(
        () => WorkspaceTimestampInput.validateRange(
          DateTime.utc(2026, 10, 7),
          DateTime.utc(2026, 10, 6),
          DateTime.utc(2026, 10, 9),
        ),
        throwsFormatException,
      );
    },
  );
  testWidgets(
    'assignment failed save retains input and dialog at compact text scale',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final repository = _AssignmentRepository()..reject = true;
      final cubit = WorkPatternCubit(repository);
      addTearDown(cubit.close);
      await cubit.bind(
        workspaceId: 'workspace-id',
        membershipId: 'membership-id',
        scope: _managerScope,
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(useMaterial3: true),
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
            child: Scaffold(
              body: Builder(
                builder: (c) => TextButton(
                  onPressed: () => showDialog<void>(
                    context: c,
                    builder: (_) => AssignmentForm(
                      repository: repository,
                      cubit: cubit,
                      workspaceId: 'workspace-id',
                      timezone: 'Africa/Cairo',
                    ),
                  ),
                  child: const Text('Open assignment'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open assignment'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Night operations').last);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('weekday-1')));
      await tester.tap(find.byKey(const Key('weekday-1')));
      await tester.pump();
      await tester.tap(find.text('Review replacement'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('confirm-work-pattern')));
      await tester.pumpAndSettle();
      expect(find.text('Assign a fixed shift'), findsOneWidget);
      expect(find.text('Captured occurrence'), findsOneWidget);
      expect(
        tester.widget<FilterChip>(find.byKey(const Key('weekday-1'))).selected,
        isTrue,
      );
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('extra form controllers survive closing dialog transitions', (
    tester,
  ) async {
    final repository = _ExtraRepository();
    final cubit = ExtraShiftsCubit(repository)
      ..bind(_managerScope, 'membership-id');
    addTearDown(cubit.close);
    await cubit.stream.firstWhere((s) => !s.loading);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (c) => TextButton(
              onPressed: () => showDialog<void>(
                context: c,
                builder: (_) => ExtraShiftForm(
                  repository: _FakeRepository(),
                  cubit: cubit,
                  workspaceId: 'workspace-id',
                  timezone: 'Africa/Cairo',
                  actual: true,
                ),
              ),
              child: const Text('Open extra'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open extra'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Inventory coverage');
    await tester.tap(find.text('Cancel'));
    await tester.pump();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(repository.requests, isEmpty);
  });
}
