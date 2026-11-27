import 'dart:async';

import 'package:go_router/go_router.dart';
import 'package:shiftly/app/app_dependencies.dart';
import 'package:shiftly/app/app_task_coordinator.dart';
import 'package:shiftly/app/session_feature_coordinator.dart';
import 'package:shiftly/app/session_router_refresh.dart';
import 'package:shiftly/app/workspace_local_cleanup.dart';
import 'package:shiftly/core/localization/language_cubit.dart';
import 'package:shiftly/core/offline/read_sync_cubit.dart';
import 'package:shiftly/core/session/session_coordinator.dart';
import 'package:shiftly/core/theme/theme_cubit.dart';
import 'package:shiftly/features/attendance/domain/repositories/attendance_repository.dart';
import 'package:shiftly/features/attendance/domain/repositories/leave_request_repository.dart';
import 'package:shiftly/features/attendance/presentation/cubit/attendance_calendar_cubit.dart';
import 'package:shiftly/features/attendance/presentation/cubit/employee_attendance_calendar_cubit.dart';
import 'package:shiftly/features/attendance/presentation/cubit/employee_attendance_cubit.dart';
import 'package:shiftly/features/attendance/presentation/cubit/employee_leave_requests_cubit.dart';
import 'package:shiftly/features/attendance/presentation/cubit/leave_requests_cubit.dart';
import 'package:shiftly/features/attendance/presentation/cubit/manager_attendance_cubit.dart';
import 'package:shiftly/features/breaks/application/shift_break_controller.dart';
import 'package:shiftly/features/chat/data/chat_realtime.dart';
import 'package:shiftly/features/chat/domain/repositories/chat_repository.dart';
import 'package:shiftly/features/chat/presentation/cubit/chat_groups_cubit.dart';
import 'package:shiftly/features/dashboard/presentation/cubit/dashboard_cubit.dart';
import 'package:shiftly/features/employees/domain/repositories/employee_repository.dart';
import 'package:shiftly/features/employees/presentation/cubit/employees_cubit.dart';
import 'package:shiftly/features/fixed_shifts/domain/repositories/fixed_shift_repository.dart';
import 'package:shiftly/features/fixed_shifts/presentation/cubit/fixed_shifts_cubit.dart';
import 'package:shiftly/features/invitations/domain/repositories/invitation_repository.dart';
import 'package:shiftly/features/notifications/domain/entities/push_notice.dart';
import 'package:shiftly/features/notifications/domain/repositories/notification_repository.dart';
import 'package:shiftly/features/notifications/domain/repositories/push_device_repository.dart';
import 'package:shiftly/features/notifications/presentation/cubit/notifications_cubit.dart';
import 'package:shiftly/features/notifications/presentation/cubit/push_notifications_cubit.dart';
import 'package:shiftly/features/onboarding/presentation/cubit/onboarding_cubit.dart';
import 'package:shiftly/features/profile/data/profile_image_picker.dart';
import 'package:shiftly/features/profile/domain/repositories/profile_repository.dart';
import 'package:shiftly/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:shiftly/features/reports/presentation/attendance_reports_cubit.dart';
import 'package:shiftly/features/shifts/domain/repositories/shift_repository.dart';
import 'package:shiftly/features/shifts/presentation/cubit/employee_shifts_cubit.dart';
import 'package:shiftly/features/shifts/presentation/cubit/manager_shifts_cubit.dart';
import 'package:shiftly/features/tasks/application/tasks_cubit.dart';
import 'package:shiftly/features/workspaces/domain/repositories/workspace_repository.dart';
import 'package:shiftly/features/workspaces/presentation/cubit/workspaces_cubit.dart';

abstract class AppCompositionState {
  AppCompositionState(
    this.dependencies, {
    required this.isMounted,
    required this.onOpened,
    required this.onForeground,
  });

  final AppDependencies dependencies;
  final bool Function() isMounted;
  final Future<void> Function(PushNotice) onOpened;
  final Future<void> Function(PushNotice) onForeground;

  late final LanguageCubit languageCubit;
  late final ThemeCubit themeCubit;
  late final ReadSyncCubit readSyncCubit;
  late final EmployeeRepository employees;
  late final InvitationRepository invitations;
  late final WorkspaceRepository workspaces;
  late final GoRouter router;
  late final OnboardingCubit onboardingCubit;
  late final DashboardCubit dashboardCubit;
  late final EmployeesCubit employeesCubit;
  late final WorkspacesCubit workspacesCubit;
  late final LeaveRequestRepository leaveRequests;
  late final ProfileRepository profile;
  late final ProfileImagePicker profileImagePicker;
  late final LeaveRequestsCubit leaveRequestsCubit;
  late final EmployeeLeaveRequestsCubit employeeLeaveRequestsCubit;
  late final ProfileCubit profileCubit;
  late final ShiftRepository shifts;
  late final AttendanceRepository attendance;
  late final ManagerShiftsCubit managerShiftsCubit;
  late final EmployeeShiftsCubit employeeShiftsCubit;
  late final ManagerAttendanceCubit managerAttendanceCubit;
  late final AttendanceCalendarCubit attendanceCalendarCubit;
  late final EmployeeAttendanceCalendarCubit employeeAttendanceCalendarCubit;
  late final AttendanceReportsCubit attendanceReportsCubit;
  late final EmployeeAttendanceCubit employeeAttendanceCubit;
  late final NotificationRepository notifications;
  late final NotificationsCubit notificationsCubit;
  late final ChatRepository chat;
  late final ChatRealtime chatRealtime;
  late final ChatGroupsCubit chatGroupsCubit;
  late final FixedShiftRepository fixedShifts;
  late final ManagerTemplatesCubit managerTemplatesCubit;
  late final FlexibleAttendanceCubit flexibleAttendanceCubit;
  late final SessionCoordinator? sessionCoordinator;
  StreamSubscription<Object?>? sessionSubscription;
  SessionRouterRefresh? sessionRefresh;
  late final SessionFeatureCoordinator featureCoordinator;
  PushNotificationsCubit? pushNotifications;
  PushDeviceRepository? pushDevices;
  late final TasksCubit tasksCubit;
  late final ShiftBreakController shiftBreaks;
  late final WorkspaceLocalCleanup workspaceRemoval;
  StreamSubscription<FlexibleAttendanceState>? breakAttendanceSubscription;
  late final AppTaskCoordinator taskCoordinator;
}
