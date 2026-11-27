import 'package:shiftly/app/app_composition_state.dart';
import 'package:shiftly/core/session/session_coordinator.dart';
import 'package:shiftly/features/attendance/presentation/cubit/employee_attendance_cubit.dart';
import 'package:shiftly/features/attendance/presentation/cubit/employee_leave_requests_cubit.dart';
import 'package:shiftly/features/attendance/presentation/cubit/leave_requests_cubit.dart';
import 'package:shiftly/features/attendance/presentation/cubit/manager_attendance_cubit.dart';
import 'package:shiftly/features/employees/presentation/cubit/employees_cubit.dart';
import 'package:shiftly/features/fixed_shifts/presentation/cubit/fixed_shifts_cubit.dart';
import 'package:shiftly/features/notifications/presentation/cubit/notifications_cubit.dart';
import 'package:shiftly/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:shiftly/features/shifts/presentation/cubit/employee_shifts_cubit.dart';
import 'package:shiftly/features/shifts/presentation/cubit/manager_shifts_cubit.dart';
import 'package:shiftly/features/workspaces/presentation/cubit/workspaces_cubit.dart';

void initializeWorkforceComposition(
  AppCompositionState c,
  T? Function<T extends Object>() registered,
  void Function() invalidateDashboardAndCalendar,
) {
  c.employeesCubit = EmployeesCubit(
    c.employees,
    invitations: c.invitations,
    onDashboardChanged: invalidateDashboardAndCalendar,
  );
  c.workspacesCubit = WorkspacesCubit(
    c.workspaces,
    c.invitations,
    onWorkspaceLeft: (id, user) => c.workspaceRemoval.remove(id, user),
    onMembershipChanged: (workspaceId, expectedUserId) async =>
        await c.sessionCoordinator?.refreshMemberships(
          preferredWorkspaceId: workspaceId,
          expectedUserId: expectedUserId,
        ) ??
        const MembershipRefreshResult.failed(),
  );
  c.leaveRequestsCubit = LeaveRequestsCubit(
    c.leaveRequests,
    onDashboardChanged: invalidateDashboardAndCalendar,
  );
  c.employeeLeaveRequestsCubit = EmployeeLeaveRequestsCubit(
    c.leaveRequests,
    onDashboardChanged: invalidateDashboardAndCalendar,
  );
  c.profileCubit = ProfileCubit(
    c.profile,
    onProfileChanged: c.sessionCoordinator?.synchronizeProfile,
  );
  c.managerShiftsCubit = ManagerShiftsCubit(
    c.shifts,
    onDashboardChanged: invalidateDashboardAndCalendar,
  );
  c.managerAttendanceCubit = ManagerAttendanceCubit(
    c.attendance,
    onDashboardChanged: invalidateDashboardAndCalendar,
  );
  c.employeeAttendanceCubit = EmployeeAttendanceCubit(c.attendance);
  c.managerTemplatesCubit =
      registered<ManagerTemplatesCubit>() ??
      ManagerTemplatesCubit(c.fixedShifts);
  c.notificationsCubit =
      registered<NotificationsCubit>() ?? NotificationsCubit(c.notifications);
  c.flexibleAttendanceCubit = FlexibleAttendanceCubit(
    c.fixedShifts,
    onAttendanceChanged: () async {
      await c.employeeAttendanceCubit.load(refresh: true);
      invalidateDashboardAndCalendar();
    },
  );
  c.employeeShiftsCubit = EmployeeShiftsCubit(
    c.shifts,
    c.attendance,
    onAttendanceChanged: () => c.employeeAttendanceCubit.load(refresh: true),
    onDashboardChanged: invalidateDashboardAndCalendar,
  );
}
