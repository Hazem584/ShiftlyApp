import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:shiftly/core/network/api_model_parser.dart';
import 'package:shiftly/core/session/feature_scope.dart';
import 'package:shiftly/features/attendance/data/leave_request_repository.dart';
import 'package:shiftly/features/attendance/presentation/cubit/employee_leave_requests_cubit.dart';
import 'package:shiftly/features/attendance/presentation/cubit/leave_requests_cubit.dart';
import 'package:shiftly/features/auth/data/models/current_user.dart';
import 'package:shiftly/features/shifts/data/shift_repository.dart';

const _managerA = FeatureSessionScope(
  userId: 'manager',
  workspaceId: 'workspace-a',
  membershipId: 'manager-a',
  timezone: 'Etc/UTC',
  role: WorkspaceRole.manager,
);
const _managerB = FeatureSessionScope(
  userId: 'manager',
  workspaceId: 'workspace-b',
  membershipId: 'manager-b',
  timezone: 'Etc/UTC',
  role: WorkspaceRole.manager,
);
const _employeeA = FeatureSessionScope(
  userId: 'employee',
  workspaceId: 'workspace-a',
  membershipId: 'employee-a',
  timezone: 'Etc/UTC',
  role: WorkspaceRole.employee,
);

LeaveRequestRecord _record({
  String workspaceId = 'workspace-a',
  String employeeId = 'employee-a',
  LeaveRequestStatus status = LeaveRequestStatus.pending,
}) => LeaveRequestRecord(
  id: 'leave-id',
  workspaceId: workspaceId,
  employeeMembershipId: employeeId,
  type: LeaveRequestType.annualLeave,
  status: status,
  startsAt: DateTime.utc(2030, 1, 1),
  endsAt: DateTime.utc(2030, 1, 2),
  reason: 'Family event',
  createdAt: DateTime.utc(2029, 12, 1),
  updatedAt: DateTime.utc(2029, 12, 1),
  employee: ShiftEmployeeSummary(
    membershipId: employeeId,
    profileId: 'profile-id',
    role: WorkspaceRole.employee,
    membershipStatus: MembershipStatus.active,
    fullName: 'Mariam Hassan',
  ),
);

LeaveRequestPage _page(LeaveRequestRecord record) => LeaveRequestPage(
  data: [record],
  pagination: const ApiPagination(page: 1, limit: 20, total: 1, totalPages: 1),
);

class _Fake implements LeaveRequestRepository {
  Completer<LeaveRequestPage>? managerList;
  Completer<LeaveRequestRecord>? createRequest;
  var reviewCalls = 0;
  var cancelCalls = 0;

  @override
  Future<LeaveRequestPage> listWorkspace(
    String workspaceId,
    LeaveRequestQuery query,
  ) =>
      managerList?.future ??
      Future.value(_page(_record(workspaceId: workspaceId)));
  @override
  Future<LeaveRequestPage> listMine(
    String workspaceId,
    LeaveRequestQuery query,
  ) async => _page(_record(workspaceId: workspaceId));
  @override
  Future<LeaveRequestRecord> create(
    String workspaceId,
    CreateLeaveRequestInput input,
  ) => createRequest?.future ?? Future.value(_record(workspaceId: workspaceId));
  @override
  Future<LeaveRequestRecord> review(
    String workspaceId,
    String requestId,
    LeaveReviewDecision decision, {
    String? rejectionReason,
  }) async {
    reviewCalls += 1;
    return _record(
      workspaceId: workspaceId,
      status: decision == LeaveReviewDecision.approved
          ? LeaveRequestStatus.approved
          : LeaveRequestStatus.rejected,
    );
  }

  @override
  Future<LeaveRequestRecord> cancelMine(String requestId) async {
    cancelCalls += 1;
    return _record(status: LeaveRequestStatus.cancelled);
  }

  @override
  Future<LeaveRequestRecord> getMine(String requestId) async => _record();
  @override
  Future<LeaveRequestRecord> getWorkspace(
    String workspaceId,
    String requestId,
  ) async => _record(workspaceId: workspaceId);
}

void main() {
  test('manager workspace switch discards a stale list response', () async {
    final repository = _Fake()..managerList = Completer<LeaveRequestPage>();
    final cubit = LeaveRequestsCubit(repository);
    cubit.bindSession(_managerA);
    await Future<void>.delayed(Duration.zero);
    cubit.bindSession(_managerB);
    repository.managerList!.complete(
      _page(_record(workspaceId: 'workspace-a')),
    );
    await Future<void>.delayed(Duration.zero);
    expect(cubit.state.requests, isEmpty);
    await cubit.close();
  });

  test(
    'logout clears employee data and ignores late create response',
    () async {
      final repository = _Fake()
        ..createRequest = Completer<LeaveRequestRecord>();
      var dashboardRefreshes = 0;
      final cubit = EmployeeLeaveRequestsCubit(
        repository,
        onDashboardChanged: () => dashboardRefreshes += 1,
      );
      cubit.bindSession(_employeeA);
      await Future<void>.delayed(Duration.zero);
      final future = cubit.create(
        CreateLeaveRequestInput(
          type: LeaveRequestType.other,
          startsAt: DateTime.utc(2030),
          endsAt: DateTime.utc(2030, 1, 2),
          reason: 'Personal',
        ),
      );
      cubit.bindSession(null);
      repository.createRequest!.complete(_record());
      expect(await future, LeaveMutationResult.stale);
      expect(cubit.state.requests, isEmpty);
      expect(dashboardRefreshes, 0);
      await cubit.close();
    },
  );

  test('manager duplicate review is suppressed and canonical response replaces item', () async {
    final repository = _Fake();
    var dashboardRefreshes = 0;
    final cubit = LeaveRequestsCubit(
      repository,
      onDashboardChanged: () => dashboardRefreshes += 1,
    )..bindSession(_managerA);
    await Future<void>.delayed(Duration.zero);
    final first = cubit.review('leave-id', LeaveReviewDecision.approved);
    final second = await cubit.review('leave-id', LeaveReviewDecision.approved);
    expect(second, LeaveMutationResult.busy);
    expect(await first, LeaveMutationResult.success);
    expect(repository.reviewCalls, 1);
    expect(cubit.state.requests.single.status, LeaveRequestStatus.approved);
    expect(dashboardRefreshes, 1);
    await cubit.close();
  });

  test('employee cancellation uses canonical cancelled response', () async {
    final repository = _Fake();
    var dashboardRefreshes = 0;
    final cubit = EmployeeLeaveRequestsCubit(
      repository,
      onDashboardChanged: () => dashboardRefreshes += 1,
    )..bindSession(_employeeA);
    await Future<void>.delayed(Duration.zero);
    expect(await cubit.cancel('leave-id'), LeaveMutationResult.success);
    expect(repository.cancelCalls, 1);
    expect(cubit.state.requests.single.status, LeaveRequestStatus.cancelled);
    expect(dashboardRefreshes, 1);
    await cubit.close();
  });
}
