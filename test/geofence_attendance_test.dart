import 'package:flutter_test/flutter_test.dart';
import 'package:shiftly/core/error/api_exception.dart';
import 'package:shiftly/core/error/failure.dart';
import 'package:shiftly/core/serialization/api_model_parser.dart';
import 'package:shiftly/core/session/feature_scope.dart';
import 'package:shiftly/features/auth/domain/entities/workspace_role.dart';
import 'package:shiftly/features/fixed_shifts/domain/repositories/fixed_shift_repository.dart';
import 'package:shiftly/features/fixed_shifts/presentation/cubit/fixed_shifts_cubit.dart';

const _scope = FeatureSessionScope(
  userId: 'user-1',
  workspaceId: 'workspace-1',
  membershipId: 'member-1',
  role: WorkspaceRole.employee,
  timezone: 'Africa/Cairo',
);

ShiftTemplate _template() => ShiftTemplate(
  id: 'template-1',
  workspaceId: 'workspace-1',
  name: 'Morning',
  color: '#334155',
  startMinute: 480,
  endMinute: 1020,
  graceMinutes: 10,
  allowedEarlyCheckInMinutes: 60,
  allowedLateCheckInMinutes: 120,
  minimumWorkMinutes: 420,
  active: true,
  overnight: false,
  createdAt: DateTime.utc(2026, 10, 1),
  updatedAt: DateTime.utc(2026, 10, 1),
);

EligibleShiftOccurrence _occurrence() => EligibleShiftOccurrence(
  occurrenceKind: 'BASELINE',
  assignmentId: 'assignment-1',
  eligible: true,
  alreadyUsed: false,
  timezone: 'Africa/Cairo',
  template: _template(),
  operationalDate: '2026-10-06',
  scheduledStartAt: DateTime.utc(2026, 10, 6, 8),
  scheduledEndAt: DateTime.utc(2026, 10, 6, 17),
  checkInWindowStart: DateTime.utc(2026, 10, 6, 7),
  checkInWindowEnd: DateTime.utc(2026, 10, 6, 10),
  classification: AttendanceClassification.onTime,
  lateMinutes: 0,
  recommended: true,
);

class _GeofenceRepo implements FixedShiftRepository {
  _GeofenceRepo(this.geofenceMode, {this.selfieMode = 'OFF'});
  final String geofenceMode;
  final String selfieMode;
  AttendanceLocationPoint? lastClockInLocation;
  String? lastSelfieBase64;
  AttendanceLocationPoint? lastClockOutLocation;
  PendingClockIn? savedPending;

  @override
  Future<TemplateEligibility> getEligibility(String workspaceId) async =>
      TemplateEligibility(
        workspaceId: workspaceId,
        geofenceMode: geofenceMode,
        selfieMode: selfieMode,
        timezone: 'Africa/Cairo',
        evaluatedAt: DateTime.utc(2026, 10, 6, 8),
        status: 'ASSIGNED',
        authorizedOccurrences: [_occurrence()],
        recommended: _occurrence(),
        eligibleTemplates: [_occurrence()],
      );

  @override
  Future<FlexibleAttendance?> getCurrentAttendance(String workspaceId) async =>
      null;

  @override
  Future<ShiftTemplatePage> listMyTemplates(
    String workspaceId, {
    int page = 1,
    int limit = 100,
  }) async => ShiftTemplatePage(
    data: [_template()],
    pagination: const ApiPagination(
      page: 1,
      limit: 100,
      total: 1,
      totalPages: 1,
    ),
  );

  @override
  Future<PendingClockIn?> loadPendingClockIn({
    required String userId,
    required String workspaceId,
    required String membershipId,
    required String templateId,
  }) async => savedPending;

  @override
  Future<void> savePendingClockIn(PendingClockIn value) async =>
      savedPending = value;

  @override
  Future<void> clearPendingClockIn(PendingClockIn value) async =>
      savedPending = null;

  @override
  Future<FlexibleAttendance> flexibleClockIn({
    required String workspaceId,
    required String shiftTemplateId,
    required String clientAttendanceId,
    String? assignmentId,
    String? extraAuthorizationId,
    AttendanceLocationPoint? location,
    String? selfieBase64,
  }) async {
    lastClockInLocation = location;
    lastSelfieBase64 = selfieBase64;
    return FlexibleAttendance(
      id: 'att-1',
      workspaceId: workspaceId,
      employeeMembershipId: 'member-1',
      source: AttendanceSource.template,
      occurrenceKind: 'BASELINE',
      assignmentId: assignmentId,
      shiftTemplateId: shiftTemplateId,
      clientAttendanceId: clientAttendanceId,
      templateName: 'Morning',
      workspaceTimezone: 'Africa/Cairo',
      operationalDate: '2026-10-06',
      scheduledStartAt: DateTime.utc(2026, 10, 6, 8),
      scheduledEndAt: DateTime.utc(2026, 10, 6, 17),
      classification: AttendanceClassification.onTime,
      clockInAt: DateTime.utc(2026, 10, 6, 8),
      minutesLate: 0,
      clockInGeoStatus: location == null ? null : 'INSIDE',
      clockInDistanceMeters: location == null ? null : 25,
      hasClockInSelfie: selfieBase64 != null,
      createdAt: DateTime.utc(2026, 10, 6, 8),
      updatedAt: DateTime.utc(2026, 10, 6, 8),
    );
  }

  @override
  Future<FlexibleAttendance> flexibleClockOut(
    String attendanceId, {
    AttendanceLocationPoint? location,
  }) async {
    lastClockOutLocation = location;
    return FlexibleAttendance(
      id: attendanceId,
      workspaceId: 'workspace-1',
      employeeMembershipId: 'member-1',
      source: AttendanceSource.template,
      occurrenceKind: 'BASELINE',
      assignmentId: 'assignment-1',
      shiftTemplateId: 'template-1',
      clientAttendanceId: 'client-1',
      templateName: 'Morning',
      workspaceTimezone: 'Africa/Cairo',
      operationalDate: '2026-10-06',
      scheduledStartAt: DateTime.utc(2026, 10, 6, 8),
      scheduledEndAt: DateTime.utc(2026, 10, 6, 17),
      classification: AttendanceClassification.onTime,
      clockInAt: DateTime.utc(2026, 10, 6, 8),
      clockOutAt: DateTime.utc(2026, 10, 6, 17),
      minutesLate: 0,
      workedMinutes: 540,
      clockOutGeoStatus: 'OUTSIDE',
      clockOutDistanceMeters: 340,
      createdAt: DateTime.utc(2026, 10, 6, 8),
      updatedAt: DateTime.utc(2026, 10, 6, 17),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('skips location reader when workspace geofenceMode is OFF', () async {
    var readerCalls = 0;
    final repo = _GeofenceRepo('OFF');
    final cubit = FlexibleAttendanceCubit(
      repo,
      locationReader: ({required requiredForPunch}) async {
        readerCalls++;
        return const AttendanceLocationPoint(latitude: 30, longitude: 31);
      },
    )..bindSession(_scope);
    await cubit.load();

    final res = await cubit.clockIn(_occurrence());
    expect(res, FixedShiftMutationResult.success);
    expect(readerCalls, 0);
    expect(repo.lastClockInLocation, isNull);
    await cubit.close();
  });

  test(
    'attaches GPS coordinates on clock-in and clock-out when ENFORCE is active',
    () async {
      final repo = _GeofenceRepo('ENFORCE');
      const point = AttendanceLocationPoint(
        latitude: 30.0444,
        longitude: 31.2357,
        accuracyMeters: 12,
      );
      final cubit = FlexibleAttendanceCubit(
        repo,
        locationReader: ({required requiredForPunch}) async => point,
      )..bindSession(_scope);
      await cubit.load();

      final inRes = await cubit.clockIn(_occurrence());
      expect(inRes, FixedShiftMutationResult.success);
      expect(repo.lastClockInLocation, point);
      expect(cubit.state.current?.clockInGeoStatus, 'INSIDE');

      final outRes = await cubit.clockOut();
      expect(outRes, FixedShiftMutationResult.success);
      expect(repo.lastClockOutLocation, point);
      expect(cubit.state.current?.clockOutGeoStatus, 'OUTSIDE');
      await cubit.close();
    },
  );

  test('clears pending clock-in and surfaces failure when location permission is denied in ENFORCE mode', () async {
    final repo = _GeofenceRepo('ENFORCE');
    final cubit = FlexibleAttendanceCubit(
      repo,
      locationReader: ({required requiredForPunch}) async {
        throw const ApiException(
          code: 'LOCATION_PERMISSION_DENIED',
          message: 'Allow location permission to record attendance at your workplace.',
          kind: FailureKind.validation,
        );
      },
    )..bindSession(_scope);
    await cubit.load();

    final res = await cubit.clockIn(_occurrence());
    expect(res, FixedShiftMutationResult.failure);
    expect(repo.savedPending, isNull);
    expect(cubit.state.failure?.message, contains('Allow location permission'));
    await cubit.close();
  });

  test(
    'captures front-camera selfie and sends base64 when selfieMode is REQUIRED',
    () async {
      final repo = _GeofenceRepo('ENFORCE', selfieMode: 'REQUIRED');
      const point = AttendanceLocationPoint(
        latitude: 30.0444,
        longitude: 31.2357,
      );
      final cubit = FlexibleAttendanceCubit(
        repo,
        locationReader: ({required requiredForPunch}) async => point,
        selfieReader: ({required requiredForPunch}) async =>
            'base64-jpeg-selfie',
      )..bindSession(_scope);
      await cubit.load();

      final res = await cubit.clockIn(_occurrence());
      expect(res, FixedShiftMutationResult.success);
      expect(repo.lastClockInLocation, point);
      expect(repo.lastSelfieBase64, 'base64-jpeg-selfie');
      expect(cubit.state.current?.hasClockInSelfie, isTrue);
      await cubit.close();
    },
  );
}
