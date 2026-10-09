import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shiftly/app.dart';
import 'package:shiftly/core/error/api_exception.dart';
import 'package:shiftly/core/session/feature_scope.dart';
import 'package:shiftly/features/auth/domain/entities/current_user.dart';
import 'package:shiftly/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:shiftly/features/dashboard/presentation/cubit/dashboard_cubit.dart';
import 'package:shiftly/features/dashboard/presentation/screens/employee_dashboard_screen.dart';
import 'package:shiftly/features/employees/data/mock_employee_repository.dart';

import 'dashboard_fixtures.dart';

class _DashboardFake implements DashboardRepository {
  _DashboardFake({ManagerDashboardData? manager})
    : manager = manager ?? dashboardManagerForPreview();

  ManagerDashboardData manager;
  EmployeeDashboardData employee = employeeDashboard(timezone: 'Etc/UTC');
  Object? error;
  int calls = 0;
  Completer<ManagerDashboardData>? pending;

  @override
  Future<ManagerDashboardData> getManagerDashboard(String workspaceId) async {
    calls += 1;
    if (pending != null) return pending!.future;
    if (error != null) throw error!;
    return manager;
  }

  @override
  Future<EmployeeDashboardData> getEmployeeDashboard(String workspaceId) async {
    if (error != null) throw error!;
    return employee;
  }
}

ManagerDashboardData dashboardManagerForPreview({
  int totalEmployees = 12,
  int scheduledToday = 4,
  int lateToday = 1,
  int missedToday = 0,
  int onApprovedLeave = 1,
}) => ManagerDashboardData.fromJson(
  managerDashboardJson(
    timezone: 'Etc/UTC',
    totalEmployees: totalEmployees,
    scheduledToday: scheduledToday,
    lateToday: lateToday,
    missedToday: missedToday,
    onApprovedLeave: onApprovedLeave,
  ),
);

void main() {
  testWidgets('renders real metrics, header integrations, and no fake trends', (
    tester,
  ) async {
    final repository = _DashboardFake();
    await tester.pumpWidget(_app(repository));
    await tester.pumpAndSettle();
    expect(find.text('Total employees'), findsOneWidget);
    expect(find.text('Scheduled today'), findsOneWidget);
    expect(find.text('Clocked in now'), findsOneWidget);
    expect(find.text('Completed today'), findsOneWidget);
    expect(find.text('12'), findsOneWidget);
    expect(find.text('4'), findsOneWidget);
    expect(find.textContaining('%'), findsNothing);
    expect(find.byKey(const Key('notification-badge')), findsOneWidget);
    expect(find.byType(CircleAvatar), findsWidgets);
    await tester.scrollUntilVisible(
      find.text('Quick actions'),
      300,
      scrollable: find
          .descendant(
            of: find.byKey(const Key('dashboard-content')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    expect(find.text('Quick actions'), findsOneWidget);
  });

  testWidgets('shows loading then error and retries safely', (tester) async {
    final repository = _DashboardFake()
      ..pending = Completer<ManagerDashboardData>();
    await tester.pumpWidget(_app(repository));
    await tester.pump();
    expect(find.textContaining('Preparing your dashboard'), findsOneWidget);
    repository.pending!.completeError(const ApiException(message: 'Offline'));
    repository.pending = null;
    await tester.pumpAndSettle();
    expect(find.text('Something went wrong'), findsOneWidget);
    expect(find.text('Offline'), findsOneWidget);
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(find.text('Total employees'), findsOneWidget);
  });

  testWidgets(
    'zero and large values fit a compact screen with long workspace',
    (tester) async {
      tester.view.physicalSize = const Size(320, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repository = _DashboardFake(
        manager: dashboardManagerForPreview(
          totalEmployees: 0,
          scheduledToday: 999999999,
          lateToday: 999999999,
          missedToday: 888888888,
          onApprovedLeave: 777777777,
        ),
      );
      await tester.pumpWidget(_app(repository));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('0'), findsWidgets);
      expect(find.text('999999999'), findsOneWidget);
      expect(find.textContaining('Preview Workspace'), findsOneWidget);
      expect(find.text('Etc/UTC'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.byKey(const Key('today-at-a-glance-card')),
        250,
        scrollable: find
            .descendant(
              of: find.byKey(const Key('dashboard-content')),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      expect(
        tester.getSize(find.byKey(const Key('today-at-a-glance-card'))).width,
        284,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('pull refresh retains cards after a background failure', (
    tester,
  ) async {
    final repository = _DashboardFake();
    await tester.pumpWidget(_app(repository));
    await tester.pumpAndSettle();
    final calls = repository.calls;
    repository.error = const ApiException(message: 'Refresh failed');
    await tester.drag(
      find.byKey(const Key('dashboard-content')),
      const Offset(0, 400),
    );
    await tester.pumpAndSettle();
    expect(repository.calls, calls + 1);
    expect(find.text('Total employees'), findsOneWidget);
    expect(find.text('Refresh failed'), findsOneWidget);
  });

  testWidgets('app resume performs one background dashboard refresh', (
    tester,
  ) async {
    final repository = _DashboardFake();
    await tester.pumpWidget(_app(repository));
    await tester.pumpAndSettle();
    final calls = repository.calls;
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(repository.calls, calls + 1);
  });

  testWidgets('employee overview renders only employee-scoped values', (
    tester,
  ) async {
    final repository = _DashboardFake()
      ..employee = employeeDashboard(timezone: 'Africa/Cairo');
    final cubit = DashboardCubit(repository)
      ..bindSession(
        const FeatureSessionScope(
          userId: 'employee-user',
          workspaceId: dashboardWorkspaceId,
          membershipId: dashboardMembershipId,
          timezone: 'Africa/Cairo',
          role: WorkspaceRole.employee,
          workspaceName: 'Cairo Store',
        ),
      );
    addTearDown(cubit.close);
    await tester.pumpWidget(
      BlocProvider.value(
        value: cubit,
        child: const MaterialApp(home: EmployeeDashboardScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Hello, Ahmed Mohamed'), findsOneWidget);
    expect(find.textContaining('Africa/Cairo'), findsOneWidget);
    expect(find.byKey(const Key('employee-quick-shifts')), findsOneWidget);
    expect(find.byKey(const Key('employee-quick-leave')), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Fixed shifts'),
      180,
      scrollable: find
          .descendant(
            of: find.byKey(const Key('employee-dashboard-content')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    expect(find.text('Fixed shifts'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Pending leave'),
      180,
      scrollable: find
          .descendant(
            of: find.byKey(const Key('employee-dashboard-content')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    expect(find.text('Pending leave'), findsOneWidget);
    expect(find.text('Total employees'), findsNothing);
  });

  testWidgets('unknown employee attendance uses a neutral label', (
    tester,
  ) async {
    final json = employeeDashboardJson(timezone: 'Etc/UTC');
    final attendance = Map<String, Object?>.from(json['attendance']! as Map)
      ..['status'] = 'A_FUTURE_BACKEND_STATUS';
    json['attendance'] = attendance;
    final repository = _DashboardFake()
      ..employee = EmployeeDashboardData.fromJson(json);
    final cubit = DashboardCubit(repository)
      ..bindSession(
        const FeatureSessionScope(
          userId: 'employee-user',
          workspaceId: dashboardWorkspaceId,
          membershipId: dashboardMembershipId,
          timezone: 'Etc/UTC',
          role: WorkspaceRole.employee,
        ),
      );
    addTearDown(cubit.close);
    await tester.pumpWidget(
      BlocProvider.value(
        value: cubit,
        child: const MaterialApp(home: EmployeeDashboardScreen()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Recorded'),
      180,
      scrollable: find
          .descendant(
            of: find.byKey(const Key('employee-dashboard-content')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    expect(find.text('Recorded'), findsOneWidget);
    expect(find.text('Clocked in'), findsNothing);
  });
}

Widget _app(DashboardRepository repository) => ShiftlyApp.preview(
  dashboardRepository: repository,
  employeeRepository: MockEmployeeRepository(delay: Duration.zero),
);
