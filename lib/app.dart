import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shiftly/core/constants/app_strings.dart';
import 'package:shiftly/core/routing/app_router.dart';
import 'package:shiftly/core/session/session_coordinator.dart';
import 'package:shiftly/core/session/session_state.dart';
import 'package:shiftly/core/session/feature_scope.dart';
import 'package:shiftly/core/theme/app_theme.dart';
import 'package:shiftly/features/auth/data/models/current_user.dart';
import 'package:shiftly/features/attendance/data/leave_request_repository.dart';
import 'package:shiftly/features/attendance/data/attendance_repository.dart';
import 'package:shiftly/features/attendance/data/attendance_calendar_repository.dart';
import 'package:shiftly/features/attendance/data/mock_attendance_repository.dart';
import 'package:shiftly/features/attendance/data/mock_leave_request_repository.dart';
import 'package:shiftly/features/attendance/presentation/cubit/leave_requests_cubit.dart';
import 'package:shiftly/features/attendance/presentation/cubit/employee_leave_requests_cubit.dart';
import 'package:shiftly/features/attendance/presentation/cubit/manager_attendance_cubit.dart';
import 'package:shiftly/features/attendance/presentation/cubit/employee_attendance_cubit.dart';
import 'package:shiftly/features/attendance/presentation/cubit/attendance_calendar_cubit.dart';
import 'package:shiftly/features/dashboard/data/dashboard_repository.dart';
import 'package:shiftly/features/dashboard/data/mock_dashboard_repository.dart';
import 'package:shiftly/features/dashboard/presentation/cubit/dashboard_cubit.dart';
import 'package:shiftly/features/chat/data/chat_realtime.dart';
import 'package:shiftly/features/chat/data/chat_repository.dart';
import 'package:shiftly/features/chat/data/mock_chat_repository.dart';
import 'package:shiftly/features/chat/presentation/cubit/chat_groups_cubit.dart';
import 'package:shiftly/features/employees/data/employee_repository.dart';
import 'package:shiftly/features/employees/data/mock_employee_repository.dart';
import 'package:shiftly/features/employees/presentation/cubit/employees_cubit.dart';
import 'package:shiftly/features/invitations/data/invitation_repository.dart';
import 'package:shiftly/features/invitations/data/mock_invitation_repository.dart';
import 'package:shiftly/features/notifications/data/mock_notification_repository.dart';
import 'package:shiftly/features/notifications/data/notification_repository.dart';
import 'package:shiftly/features/notifications/presentation/cubit/notifications_cubit.dart';
import 'package:shiftly/features/profile/data/mock_profile_repository.dart';
import 'package:shiftly/features/profile/data/profile_image_picker.dart';
import 'package:shiftly/features/profile/data/profile_repository.dart';
import 'package:shiftly/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:shiftly/features/shifts/data/mock_shift_repository.dart';
import 'package:shiftly/features/shifts/data/shift_repository.dart';
import 'package:shiftly/features/shifts/presentation/cubit/employee_shifts_cubit.dart';
import 'package:shiftly/features/shifts/presentation/cubit/manager_shifts_cubit.dart';
import 'package:shiftly/features/workspaces/data/mock_workspace_repository.dart';
import 'package:shiftly/features/workspaces/data/workspace_repository.dart';
import 'package:shiftly/features/workspaces/presentation/cubit/workspaces_cubit.dart';

class ShiftlyApp extends StatefulWidget {
  const ShiftlyApp({
    super.key,
    this.employeeRepository,
    this.invitationRepository,
    this.workspaceRepository,
    this.dashboardRepository,
    this.leaveRequestRepository,
    this.profileRepository,
    this.profileImagePicker,
    this.router,
    this.sessionCoordinator,
    this.shiftRepository,
    this.attendanceRepository,
    this.notificationRepository,
    this.chatRepository,
    this.chatRealtime,
  });

  final EmployeeRepository? employeeRepository;
  final InvitationRepository? invitationRepository;
  final WorkspaceRepository? workspaceRepository;
  final DashboardRepository? dashboardRepository;
  final LeaveRequestRepository? leaveRequestRepository;
  final ProfileRepository? profileRepository;
  final ProfileImagePicker? profileImagePicker;
  final GoRouter? router;
  final SessionCoordinator? sessionCoordinator;
  final ShiftRepository? shiftRepository;
  final AttendanceRepository? attendanceRepository;
  final NotificationRepository? notificationRepository;
  final ChatRepository? chatRepository;
  final ChatRealtime? chatRealtime;

  @override
  State<ShiftlyApp> createState() => _ShiftlyAppState();
}

class _ShiftlyAppState extends State<ShiftlyApp> with WidgetsBindingObserver {
  late final EmployeeRepository _employees;
  late final InvitationRepository _invitations;
  late final WorkspaceRepository _workspaces;
  late final GoRouter _router;
  late final DashboardCubit _dashboardCubit;
  late final EmployeesCubit _employeesCubit;
  late final WorkspacesCubit _workspacesCubit;
  late final LeaveRequestRepository _leaveRequests;
  late final ProfileRepository _profile;
  late final ProfileImagePicker _profileImagePicker;
  late final LeaveRequestsCubit _leaveRequestsCubit;
  late final EmployeeLeaveRequestsCubit _employeeLeaveRequestsCubit;
  late final ProfileCubit _profileCubit;
  late final ShiftRepository _shifts;
  late final AttendanceRepository _attendance;
  late final ManagerShiftsCubit _managerShiftsCubit;
  late final EmployeeShiftsCubit _employeeShiftsCubit;
  late final ManagerAttendanceCubit _managerAttendanceCubit;
  late final AttendanceCalendarCubit _attendanceCalendarCubit;
  late final EmployeeAttendanceCubit _employeeAttendanceCubit;
  late final NotificationRepository _notifications;
  late final NotificationsCubit _notificationsCubit;
  late final ChatRepository _chat;
  late final ChatRealtime _chatRealtime;
  late final ChatGroupsCubit _chatGroupsCubit;
  StreamSubscription<Object?>? _sessionSubscription;
  _SessionRouterRefresh? _sessionRefresh;

  @override
  void initState() {
    super.initState();
    _employees = widget.employeeRepository ?? MockEmployeeRepository();
    _invitations = widget.invitationRepository ?? MockInvitationRepository();
    _workspaces = widget.workspaceRepository ?? MockWorkspaceRepository();
    final dashboard =
        widget.dashboardRepository ??
        (widget.sessionCoordinator == null
            ? MockDashboardRepository(
                employeeRepository: MockEmployeeRepository(),
              )
            : throw StateError(
                'Authenticated apps must inject DashboardRepository.',
              ));
    _sessionRefresh = widget.sessionCoordinator == null
        ? null
        : _SessionRouterRefresh(widget.sessionCoordinator!);
    _router =
        widget.router ??
        createAppRouter(
          sessionCoordinator: widget.sessionCoordinator,
          refreshListenable: _sessionRefresh,
        );
    _leaveRequests =
        widget.leaveRequestRepository ?? MockLeaveRequestRepository();
    _profile = widget.profileRepository ?? MockProfileRepository();
    _profileImagePicker =
        widget.profileImagePicker ?? DeviceProfileImagePicker();
    _shifts = widget.shiftRepository ?? const MockShiftRepository();
    _attendance =
        widget.attendanceRepository ?? const MockAttendanceRepository();
    _notifications =
        widget.notificationRepository ??
        (widget.sessionCoordinator == null
            ? MockNotificationRepository()
            : throw StateError(
                'Authenticated apps must inject NotificationRepository.',
              ));
    _dashboardCubit = DashboardCubit(dashboard);
    _attendanceCalendarCubit = AttendanceCalendarCubit(
      ApiAttendanceCalendarRepository(_shifts, _attendance, _leaveRequests),
    );
    _employeesCubit = EmployeesCubit(
      _employees,
      invitations: _invitations,
      onDashboardChanged: _invalidateDashboardAndCalendar,
    );
    _workspacesCubit = WorkspacesCubit(
      _workspaces,
      _invitations,
      onMembershipChanged: (workspaceId, expectedUserId) async =>
          await widget.sessionCoordinator?.refreshMemberships(
            preferredWorkspaceId: workspaceId,
            expectedUserId: expectedUserId,
          ) ??
          const MembershipRefreshResult.failed(),
    );
    _leaveRequestsCubit = LeaveRequestsCubit(
      _leaveRequests,
      onDashboardChanged: _invalidateDashboardAndCalendar,
    );
    _employeeLeaveRequestsCubit = EmployeeLeaveRequestsCubit(
      _leaveRequests,
      onDashboardChanged: _invalidateDashboardAndCalendar,
    );
    _profileCubit = ProfileCubit(
      _profile,
      onProfileChanged: widget.sessionCoordinator?.synchronizeProfile,
    );
    _managerShiftsCubit = ManagerShiftsCubit(
      _shifts,
      onDashboardChanged: _invalidateDashboardAndCalendar,
    );
    _managerAttendanceCubit = ManagerAttendanceCubit(
      _attendance,
      onDashboardChanged: _invalidateDashboardAndCalendar,
    );
    _employeeAttendanceCubit = EmployeeAttendanceCubit(_attendance);
    _employeeShiftsCubit = EmployeeShiftsCubit(
      _shifts,
      _attendance,
      onAttendanceChanged: () => _employeeAttendanceCubit.load(refresh: true),
      onDashboardChanged: _invalidateDashboardAndCalendar,
    );
    _notificationsCubit = NotificationsCubit(_notifications);
    _chat = widget.chatRepository ?? const MockChatRepository();
    _chatRealtime = widget.chatRealtime ?? const NoopChatRealtime();
    _chatGroupsCubit = ChatGroupsCubit(_chat);
    WidgetsBinding.instance.addObserver(this);
    final coordinator = widget.sessionCoordinator;
    if (coordinator == null) {
      _profileCubit.load();
      _employeesCubit.load();
      const previewScope = FeatureSessionScope(
        userId: 'preview-user',
        workspaceId: 'preview-workspace',
        membershipId: 'preview-membership',
        timezone: 'Etc/UTC',
        role: WorkspaceRole.manager,
        workspaceName: 'Shift Lab Preview Workspace',
      );
      _managerShiftsCubit.bindSession(previewScope);
      _managerAttendanceCubit.bindSession(previewScope);
      _leaveRequestsCubit.bindSession(previewScope);
      _notificationsCubit.bindSession(previewScope);
      _dashboardCubit.bindSession(previewScope);
      _chatGroupsCubit.bindSession(previewScope);
    } else {
      _sessionSubscription = coordinator.stream.listen(_bindSession);
      _bindSession(coordinator.state);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _dashboardCubit.close();
    _employeesCubit.close();
    _workspacesCubit.close();
    _leaveRequestsCubit.close();
    _employeeLeaveRequestsCubit.close();
    _profileCubit.close();
    _managerShiftsCubit.close();
    _employeeShiftsCubit.close();
    _managerAttendanceCubit.close();
    _attendanceCalendarCubit.close();
    _employeeAttendanceCubit.close();
    _notificationsCubit.close();
    _chatGroupsCubit.close();
    _sessionSubscription?.cancel();
    _sessionRefresh?.dispose();
    widget.sessionCoordinator?.close();
    if (widget.router == null) _router.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_notificationsCubit.refreshUnreadCount());
      unawaited(_chatGroupsCubit.refreshUnread());
      _dashboardCubit.invalidate();
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: _employees),
        RepositoryProvider.value(value: _invitations),
        RepositoryProvider.value(value: _workspaces),
        RepositoryProvider.value(value: _leaveRequests),
        RepositoryProvider.value(value: _profile),
        RepositoryProvider.value(value: _profileImagePicker),
        RepositoryProvider.value(value: _shifts),
        RepositoryProvider.value(value: _attendance),
        RepositoryProvider.value(value: _notifications),
        RepositoryProvider<ChatRepository>.value(value: _chat),
        RepositoryProvider<ChatRealtime>.value(value: _chatRealtime),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider.value(value: _dashboardCubit),
          BlocProvider.value(value: _employeesCubit),
          BlocProvider.value(value: _workspacesCubit),
          BlocProvider.value(value: _leaveRequestsCubit),
          BlocProvider.value(value: _employeeLeaveRequestsCubit),
          BlocProvider.value(value: _profileCubit),
          BlocProvider.value(value: _managerShiftsCubit),
          BlocProvider.value(value: _employeeShiftsCubit),
          BlocProvider.value(value: _managerAttendanceCubit),
          BlocProvider.value(value: _attendanceCalendarCubit),
          BlocProvider.value(value: _employeeAttendanceCubit),
          BlocProvider.value(value: _notificationsCubit),
          BlocProvider.value(value: _chatGroupsCubit),
        ],
        child: MaterialApp.router(
          title: AppStrings.appName,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme(),
          routerConfig: _router,
        ),
      ),
    );
    final coordinator = widget.sessionCoordinator;
    return coordinator == null
        ? app
        : BlocProvider<SessionCoordinator>.value(
            value: coordinator,
            child: app,
          );
  }

  void _bindSession(SessionState state) {
    _profileCubit.bindSession(_profileScope(state));
    _employeesCubit.bindSession(_employeeScope(state));
    _workspacesCubit.bindUser(state.currentUser?.id);
    final featureScope = _featureScope(state);
    _managerShiftsCubit.bindSession(featureScope);
    _employeeShiftsCubit.bindSession(featureScope);
    _managerAttendanceCubit.bindSession(featureScope);
    _attendanceCalendarCubit.bindSession(featureScope);
    _employeeAttendanceCubit.bindSession(featureScope);
    _leaveRequestsCubit.bindSession(featureScope);
    _employeeLeaveRequestsCubit.bindSession(featureScope);
    _notificationsCubit.bindSession(featureScope);
    _dashboardCubit.bindSession(featureScope);
    _chatGroupsCubit.bindSession(featureScope);
  }

  void _invalidateDashboardAndCalendar() {
    _dashboardCubit.invalidate();
    _attendanceCalendarCubit.invalidate();
  }
}

FeatureSessionScope? _featureScope(SessionState state) {
  final user = state.currentUser;
  final membership = state.activeMembership;
  if (!state.isAuthenticated || user == null || membership == null) return null;
  if (membership.status != MembershipStatus.active ||
      membership.role == WorkspaceRole.unknown) {
    return null;
  }
  return FeatureSessionScope(
    userId: user.id,
    workspaceId: membership.workspace.id,
    membershipId: membership.id,
    timezone: membership.workspace.timezone,
    role: membership.role,
    workspaceName: membership.workspace.name,
  );
}

ProfileSessionScope? _profileScope(SessionState state) {
  final user = state.currentUser;
  final membership = state.activeMembership;
  if (!state.isAuthenticated || user == null || membership == null) return null;
  return ProfileSessionScope(
    userId: user.id,
    workspaceId: membership.workspace.id,
  );
}

EmployeeSessionScope? _employeeScope(SessionState state) {
  final user = state.currentUser;
  final membership = state.activeMembership;
  if (!state.isAuthenticated || user == null || membership == null) return null;
  return EmployeeSessionScope(
    userId: user.id,
    workspaceId: membership.workspace.id,
    role: membership.role,
  );
}

class _SessionRouterRefresh extends ChangeNotifier {
  _SessionRouterRefresh(SessionCoordinator coordinator) {
    _subscription = coordinator.stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<Object?> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
