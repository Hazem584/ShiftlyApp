import 'package:shiftly/app/app_dependencies.dart';
import 'package:shiftly/features/attendance/data/mock_attendance_repository.dart';
import 'package:shiftly/features/attendance/data/mock_leave_request_repository.dart';
import 'package:shiftly/features/attendance/domain/repositories/attendance_repository.dart';
import 'package:shiftly/features/attendance/domain/repositories/leave_request_repository.dart';
import 'package:shiftly/features/dashboard/data/mock_dashboard_repository.dart';
import 'package:shiftly/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:shiftly/features/employees/data/mock_employee_repository.dart';
import 'package:shiftly/features/employees/domain/repositories/employee_repository.dart';
import 'package:shiftly/features/fixed_shifts/data/preview_fixed_shift_repository.dart';
import 'package:shiftly/features/fixed_shifts/domain/repositories/fixed_shift_repository.dart';
import 'package:shiftly/features/invitations/data/mock_invitation_repository.dart';
import 'package:shiftly/features/invitations/domain/repositories/invitation_repository.dart';
import 'package:shiftly/features/notifications/data/mock_notification_repository.dart';
import 'package:shiftly/features/notifications/domain/repositories/notification_repository.dart';
import 'package:shiftly/features/profile/data/mock_profile_repository.dart';
import 'package:shiftly/features/profile/data/profile_image_picker.dart';
import 'package:shiftly/features/profile/domain/repositories/profile_repository.dart';
import 'package:shiftly/features/shifts/data/mock_shift_repository.dart';
import 'package:shiftly/features/shifts/domain/repositories/shift_repository.dart';
import 'package:shiftly/features/workspaces/data/mock_workspace_repository.dart';
import 'package:shiftly/features/workspaces/domain/repositories/workspace_repository.dart';

class AppRepositories {
  AppRepositories(
    AppDependencies dependencies,
    T? Function<T extends Object>() registered,
  ) {
    employees =
        dependencies.employeeRepository ??
        registered<EmployeeRepository>() ??
        MockEmployeeRepository();
    invitations =
        dependencies.invitationRepository ??
        registered<InvitationRepository>() ??
        MockInvitationRepository();
    workspaces =
        dependencies.workspaceRepository ??
        registered<WorkspaceRepository>() ??
        MockWorkspaceRepository();
    dashboard =
        dependencies.dashboardRepository ??
        registered<DashboardRepository>() ??
        (dependencies.preview
            ? MockDashboardRepository(
                employeeRepository: MockEmployeeRepository(),
              )
            : throw StateError(
                'Authenticated apps must inject DashboardRepository.',
              ));
    leaveRequests =
        dependencies.leaveRequestRepository ??
        registered<LeaveRequestRepository>() ??
        MockLeaveRequestRepository();
    profile =
        dependencies.profileRepository ??
        registered<ProfileRepository>() ??
        MockProfileRepository();
    profileImagePicker =
        dependencies.profileImagePicker ??
        registered<ProfileImagePicker>() ??
        DeviceProfileImagePicker();
    shifts =
        dependencies.shiftRepository ??
        registered<ShiftRepository>() ??
        const MockShiftRepository();
    attendance =
        dependencies.attendanceRepository ??
        registered<AttendanceRepository>() ??
        const MockAttendanceRepository();
    fixedShifts =
        dependencies.fixedShiftRepository ??
        registered<FixedShiftRepository>() ??
        (dependencies.preview
            ? const PreviewFixedShiftRepository()
            : throw StateError(
                'Authenticated apps must inject FixedShiftRepository.',
              ));
    notifications =
        dependencies.notificationRepository ??
        registered<NotificationRepository>() ??
        (dependencies.preview
            ? MockNotificationRepository()
            : throw StateError(
                'Authenticated apps must inject NotificationRepository.',
              ));
  }
  late final EmployeeRepository employees;
  late final InvitationRepository invitations;
  late final WorkspaceRepository workspaces;
  late final DashboardRepository dashboard;
  late final LeaveRequestRepository leaveRequests;
  late final ProfileRepository profile;
  late final ProfileImagePicker profileImagePicker;
  late final ShiftRepository shifts;
  late final AttendanceRepository attendance;
  late final FixedShiftRepository fixedShifts;
  late final NotificationRepository notifications;
}
