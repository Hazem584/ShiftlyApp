import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:shiftly/core/error/api_exception.dart';
import 'package:shiftly/core/session/feature_scope.dart';
import 'package:shiftly/features/auth/data/models/current_user.dart';
import 'package:shiftly/features/dashboard/data/dashboard_repository.dart';
import 'package:shiftly/features/dashboard/presentation/cubit/dashboard_cubit.dart';

import 'dashboard_fixtures.dart';

const _managerA = FeatureSessionScope(
  userId: 'user-a',
  workspaceId: dashboardWorkspaceId,
  membershipId: '15147f4c-bdca-4a81-a631-fd2253aeb1b8',
  timezone: 'Africa/Cairo',
  role: WorkspaceRole.manager,
  workspaceName: 'Cairo Store',
);
const _employeeA = FeatureSessionScope(
  userId: 'user-a',
  workspaceId: dashboardWorkspaceId,
  membershipId: dashboardMembershipId,
  timezone: 'Africa/Cairo',
  role: WorkspaceRole.employee,
  workspaceName: 'Cairo Store',
);

class _Fake implements DashboardRepository {
  ManagerDashboardData manager = managerDashboard();
  EmployeeDashboardData employee = employeeDashboard();
  Object? error;
  int managerCalls = 0;
  int employeeCalls = 0;
  final managerCompleters = <Completer<ManagerDashboardData>>[];

  @override
  Future<ManagerDashboardData> getManagerDashboard(String workspaceId) async {
    managerCalls += 1;
    if (managerCompleters.isNotEmpty) {
      return managerCompleters.removeAt(0).future;
    }
    if (error != null) throw error!;
    return manager;
  }

  @override
  Future<EmployeeDashboardData> getEmployeeDashboard(String workspaceId) async {
    employeeCalls += 1;
    if (error != null) throw error!;
    return employee;
  }
}

Future<void> _settle() => Future<void>.delayed(Duration.zero);

void main() {
  test('loads manager and employee dashboards for their exact role', () async {
    final repository = _Fake();
    final cubit = DashboardCubit(repository)..bindSession(_managerA);
    expect(cubit.state, isA<DashboardLoading>());
    await _settle();
    expect((cubit.state as DashboardLoaded).data, isA<ManagerDashboardData>());
    cubit.bindSession(_employeeA);
    await _settle();
    expect((cubit.state as DashboardLoaded).data, isA<EmployeeDashboardData>());
    expect(repository.managerCalls, 1);
    expect(repository.employeeCalls, 1);
    await cubit.close();
  });

  test('supports a canonical empty dashboard', () async {
    final repository = _Fake()
      ..manager = ManagerDashboardData.fromJson(
        managerDashboardJson(
          totalEmployees: 0,
          scheduledToday: 0,
          clockedInNow: 0,
          completedToday: 0,
          lateToday: 0,
          missedToday: 0,
          onApprovedLeave: 0,
          pendingLeaveRequests: 0,
          unreadNotifications: 0,
          todayShifts: [],
          pendingLeaves: [],
        ),
      );
    final cubit = DashboardCubit(repository)..bindSession(_managerA);
    await _settle();
    expect((cubit.state as DashboardLoaded).data.isEmpty, isTrue);
    await cubit.close();
  });

  test('first-load failure retries successfully', () async {
    final repository = _Fake()..error = const ApiException(message: 'Offline');
    final cubit = DashboardCubit(repository)..bindSession(_managerA);
    await _settle();
    expect((cubit.state as DashboardError).failure.message, 'Offline');
    repository.error = null;
    await cubit.load();
    expect(cubit.state, isA<DashboardLoaded>());
    await cubit.close();
  });

  test('refresh failure retains canonical dashboard', () async {
    final repository = _Fake();
    final cubit = DashboardCubit(repository)..bindSession(_managerA);
    await _settle();
    repository.error = const ApiException(message: 'Refresh failed');
    await cubit.load(refresh: true);
    final state = cubit.state as DashboardLoaded;
    expect(state.data, repository.manager);
    expect(state.refreshing, isFalse);
    expect(state.failure?.message, 'Refresh failed');
    await cubit.close();
  });

  test('coalesces simultaneous refresh triggers into one follow-up', () async {
    final first = Completer<ManagerDashboardData>();
    final second = Completer<ManagerDashboardData>();
    final repository = _Fake()..managerCompleters.addAll([first, second]);
    final cubit = DashboardCubit(repository)..bindSession(_managerA);
    cubit.invalidate();
    cubit.invalidate();
    expect(repository.managerCalls, 1);
    first.complete(repository.manager);
    await _settle();
    expect(repository.managerCalls, 2);
    second.complete(repository.manager);
    await _settle();
    expect(repository.managerCalls, 2);
    await cubit.close();
  });

  test(
    'workspace, user, role, logout and stale responses are isolated',
    () async {
      final stale = Completer<ManagerDashboardData>();
      final repository = _Fake()..managerCompleters.add(stale);
      final cubit = DashboardCubit(repository)..bindSession(_managerA);
      const managerB = FeatureSessionScope(
        userId: 'user-a',
        workspaceId: 'b5e624e8-ee45-4417-a932-5b48ad019657',
        membershipId: '25147f4c-bdca-4a81-a631-fd2253aeb1b9',
        timezone: 'Africa/Cairo',
        role: WorkspaceRole.manager,
      );
      cubit.bindSession(managerB);
      await _settle();
      expect(
        (cubit.state as DashboardLoaded).data,
        isA<ManagerDashboardData>(),
      );
      cubit.bindSession(_employeeA);
      await _settle();
      expect(
        (cubit.state as DashboardLoaded).data,
        isA<EmployeeDashboardData>(),
      );
      final employeeB = _employeeA.copyWithForTest(userId: 'user-b');
      cubit.bindSession(employeeB);
      expect(cubit.state, isA<DashboardLoading>());
      stale.complete(repository.manager);
      await _settle();
      expect(
        (cubit.state as DashboardLoaded).data,
        isA<EmployeeDashboardData>(),
      );
      cubit.bindSession(null);
      expect(cubit.state, isA<DashboardLoading>());
      await cubit.close();
    },
  );

  test('same-session refresh does not reset or request again', () async {
    final repository = _Fake();
    final cubit = DashboardCubit(repository)..bindSession(_managerA);
    await _settle();
    final state = cubit.state;
    cubit.bindSession(_managerA);
    expect(cubit.state, same(state));
    expect(repository.managerCalls, 1);
    await cubit.close();
  });

  test('unknown or suspended/absent scopes never request data', () async {
    final repository = _Fake();
    final cubit = DashboardCubit(repository)
      ..bindSession(
        const FeatureSessionScope(
          userId: 'user',
          workspaceId: dashboardWorkspaceId,
          membershipId: dashboardMembershipId,
          timezone: 'Africa/Cairo',
          role: WorkspaceRole.unknown,
        ),
      );
    expect(repository.managerCalls + repository.employeeCalls, 0);
    cubit.bindSession(null);
    expect(repository.managerCalls + repository.employeeCalls, 0);
    await cubit.close();
  });

  test('rejects employee identity and timezone mismatches', () async {
    final repository = _Fake()
      ..employee = EmployeeDashboardData.fromJson(
        employeeDashboardJson(
          membershipId: '15147f4c-bdca-4a81-a631-fd2253aeb1b8',
        ),
      );
    final cubit = DashboardCubit(repository)..bindSession(_employeeA);
    await _settle();
    expect(cubit.state, isA<DashboardError>());
    await cubit.close();
  });
}

extension on FeatureSessionScope {
  FeatureSessionScope copyWithForTest({required String userId}) =>
      FeatureSessionScope(
        userId: userId,
        workspaceId: workspaceId,
        membershipId: membershipId,
        timezone: timezone,
        role: role,
        workspaceName: workspaceName,
      );
}
