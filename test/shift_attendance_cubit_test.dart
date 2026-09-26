import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:shiftly/core/network/api_model_parser.dart';
import 'package:shiftly/core/session/feature_scope.dart';
import 'package:shiftly/features/attendance/data/attendance_repository.dart';
import 'package:shiftly/features/attendance/presentation/cubit/manager_attendance_cubit.dart';
import 'package:shiftly/features/auth/data/models/current_user.dart';
import 'package:shiftly/features/shifts/data/shift_repository.dart';
import 'package:shiftly/features/shifts/presentation/cubit/employee_shifts_cubit.dart';
import 'package:shiftly/features/shifts/presentation/cubit/manager_shifts_cubit.dart';

const _managerScope = FeatureSessionScope(
  userId: 'manager-user',
  workspaceId: 'workspace-id',
  timezone: 'Africa/Cairo',
  role: WorkspaceRole.manager,
);
const _employeeScope = FeatureSessionScope(
  userId: 'employee-user',
  workspaceId: 'workspace-id',
  timezone: 'Africa/Cairo',
  role: WorkspaceRole.employee,
);

ApiPagination _pagination({int total = 1}) => ApiPagination(
  page: 1,
  limit: 20,
  total: total,
  totalPages: total == 0 ? 0 : 1,
);

ShiftEmployeeSummary _employee() => const ShiftEmployeeSummary(
  membershipId: 'membership-id',
  profileId: 'profile-id',
  role: WorkspaceRole.employee,
  membershipStatus: MembershipStatus.active,
  fullName: 'Mariam Hassan',
);

ShiftRecord _shift({String workspaceId = 'workspace-id'}) => ShiftRecord(
  id: 'shift-id',
  workspaceId: workspaceId,
  employeeMembershipId: 'membership-id',
  createdByMembershipId: 'manager-membership-id',
  startsAt: DateTime.utc(2026, 9, 26, 6),
  endsAt: DateTime.utc(2026, 9, 26, 14),
  breakMinutes: 30,
  graceMinutes: 10,
  status: ShiftStatus.scheduled,
  createdAt: DateTime.utc(2026, 9, 20),
  updatedAt: DateTime.utc(2026, 9, 20),
  employee: _employee(),
);

AttendanceRecordApi _attendance({
  AttendanceReviewStatus reviewStatus = AttendanceReviewStatus.pending,
}) => AttendanceRecordApi(
  id: 'attendance-id',
  workspaceId: 'workspace-id',
  shiftId: 'shift-id',
  employeeMembershipId: 'membership-id',
  clockInAt: DateTime.utc(2026, 9, 26, 6, 5),
  reviewStatus: reviewStatus,
  minutesLate: 0,
  createdAt: DateTime.utc(2026, 9, 26, 6, 5),
  updatedAt: DateTime.utc(2026, 9, 26, 6, 5),
  shift: AttendanceShiftSummary(
    id: 'shift-id',
    startsAt: DateTime.utc(2026, 9, 26, 6),
    endsAt: DateTime.utc(2026, 9, 26, 14),
    breakMinutes: 30,
    graceMinutes: 10,
    status: ShiftStatus.scheduled,
  ),
  employee: _employee(),
);

class _ShiftFake implements ShiftRepository {
  _ShiftFake({this.listCompleter});
  final Completer<ShiftPage>? listCompleter;
  ShiftRecord record = _shift();

  @override
  Future<ShiftPage> listWorkspaceShifts(String workspaceId, ShiftQuery query) =>
      listCompleter?.future ??
      Future.value(ShiftPage(data: [record], pagination: _pagination()));
  @override
  Future<ShiftPage> listMyShifts(ShiftQuery query) async =>
      ShiftPage(data: [record], pagination: _pagination());
  @override
  Future<ShiftRecord> getWorkspaceShift(
    String workspaceId,
    String shiftId,
  ) async => record;
  @override
  Future<ShiftRecord> getMyShift(String shiftId) async => record;
  @override
  Future<ShiftRecord> createShift(
    String workspaceId,
    CreateShiftInput input,
  ) async => record;
  @override
  Future<ShiftRecord> updateShift(
    String workspaceId,
    String shiftId,
    UpdateShiftInput input,
  ) async => record;
  @override
  Future<ShiftRecord> cancelShift(String workspaceId, String shiftId) async =>
      record.copyWith(status: ShiftStatus.cancelled);
}

class _AttendanceFake implements AttendanceRepository {
  final clockCompleter = Completer<AttendanceRecordApi>();
  var reviewCalls = 0;

  @override
  Future<AttendanceRecordApi> clockIn(String shiftId) => clockCompleter.future;
  @override
  Future<AttendanceRecordApi> clockOut(String shiftId) => clockCompleter.future;
  @override
  Future<AttendancePage> listWorkspaceAttendance(
    String workspaceId,
    AttendanceQuery query,
  ) async => AttendancePage(data: [_attendance()], pagination: _pagination());
  @override
  Future<AttendancePage> listAttendanceRequests(
    String workspaceId, {
    int page = 1,
    int limit = 20,
  }) async => AttendancePage(data: [_attendance()], pagination: _pagination());
  @override
  Future<AttendancePage> listMyAttendance(AttendanceQuery query) async =>
      AttendancePage(data: [_attendance()], pagination: _pagination());
  @override
  Future<AttendanceRecordApi> getWorkspaceAttendance(
    String workspaceId,
    String attendanceId,
  ) async => _attendance();
  @override
  Future<AttendanceRecordApi> reviewAttendance(
    String workspaceId,
    String attendanceId,
    AttendanceReviewDecision decision, {
    String? rejectionReason,
  }) async {
    reviewCalls += 1;
    return _attendance(
      reviewStatus: decision == AttendanceReviewDecision.approved
          ? AttendanceReviewStatus.approved
          : AttendanceReviewStatus.rejected,
    );
  }
}

void main() {
  test('logout invalidates an in-flight manager shift response', () async {
    final completer = Completer<ShiftPage>();
    final cubit = ManagerShiftsCubit(_ShiftFake(listCompleter: completer));
    addTearDown(cubit.close);
    cubit.bindSession(_managerScope);
    expect(cubit.state.initialLoading, isTrue);
    cubit.bindSession(null);
    completer.complete(ShiftPage(data: [_shift()], pagination: _pagination()));
    await Future<void>.delayed(Duration.zero);
    expect(cubit.state.records, isEmpty);
    expect(cubit.state.initialLoading, isTrue);
  });

  test('shift validation accepts overnight and rejects invalid ranges', () {
    expect(
      ManagerShiftsCubit.validateShift(
        startsAt: DateTime.utc(2026, 9, 26, 22),
        endsAt: DateTime.utc(2026, 9, 27, 6),
        breakMinutes: 30,
        graceMinutes: 10,
      ),
      isNull,
    );
    expect(
      ManagerShiftsCubit.validateShift(
        startsAt: DateTime.utc(2026, 9, 27, 6),
        endsAt: DateTime.utc(2026, 9, 26, 22),
        breakMinutes: 30,
        graceMinutes: 10,
      ),
      isNotNull,
    );
  });

  test('clock-in prevents duplicates and applies canonical response', () async {
    final shifts = _ShiftFake();
    final attendance = _AttendanceFake();
    final cubit = EmployeeShiftsCubit(shifts, attendance);
    addTearDown(cubit.close);
    cubit.bindSession(_employeeScope);
    await cubit.stream.firstWhere((state) => !state.initialLoading);

    final first = cubit.clockIn('shift-id');
    final duplicate = await cubit.clockIn('shift-id');
    expect(duplicate, ClockMutationResult.busy);
    attendance.clockCompleter.complete(_attendance());
    expect(await first, ClockMutationResult.success);
    expect(cubit.state.records.single.attendance?.id, 'attendance-id');
    expect(cubit.state.clockingInIds, isEmpty);
  });

  test(
    'attendance review requires a reason and removes approved request',
    () async {
      final repository = _AttendanceFake();
      final cubit = ManagerAttendanceCubit(repository);
      addTearDown(cubit.close);
      cubit.bindSession(_managerScope);
      await cubit.stream.firstWhere((state) => !state.initialLoading);

      final invalid = await cubit.review(
        'attendance-id',
        AttendanceReviewDecision.rejected,
        rejectionReason: '   ',
      );
      expect(invalid, AttendanceMutationResult.failure);
      expect(repository.reviewCalls, 0);

      final approved = await cubit.review(
        'attendance-id',
        AttendanceReviewDecision.approved,
      );
      expect(approved, AttendanceMutationResult.success);
      expect(cubit.state.pending, isEmpty);
      expect(
        cubit.state.records.single.reviewStatus,
        AttendanceReviewStatus.approved,
      );
    },
  );
}
