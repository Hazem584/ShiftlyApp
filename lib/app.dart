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
import 'package:shiftly/features/attendance/data/mock_attendance_repository.dart';
import 'package:shiftly/features/attendance/data/mock_leave_request_repository.dart';
import 'package:shiftly/features/attendance/presentation/cubit/leave_requests_cubit.dart';
import 'package:shiftly/features/attendance/presentation/cubit/manager_attendance_cubit.dart';
import 'package:shiftly/features/attendance/presentation/cubit/employee_attendance_cubit.dart';
import 'package:shiftly/features/dashboard/data/dashboard_repository.dart';
import 'package:shiftly/features/dashboard/data/mock_dashboard_repository.dart';
import 'package:shiftly/features/dashboard/presentation/cubit/dashboard_cubit.dart';
import 'package:shiftly/features/employees/data/employee_repository.dart';
import 'package:shiftly/features/employees/data/mock_employee_repository.dart';
import 'package:shiftly/features/employees/presentation/cubit/employees_cubit.dart';
import 'package:shiftly/features/invitations/data/invitation_repository.dart';
import 'package:shiftly/features/invitations/data/mock_invitation_repository.dart';
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

  @override
  State<ShiftlyApp> createState() => _ShiftlyAppState();
}

class _ShiftlyAppState extends State<ShiftlyApp> {
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
  late final ProfileCubit _profileCubit;
  late final ShiftRepository _shifts;
  late final AttendanceRepository _attendance;
  late final ManagerShiftsCubit _managerShiftsCubit;
  late final EmployeeShiftsCubit _employeeShiftsCubit;
  late final ManagerAttendanceCubit _managerAttendanceCubit;
  late final EmployeeAttendanceCubit _employeeAttendanceCubit;
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
        MockDashboardRepository(employeeRepository: MockEmployeeRepository());
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
    _dashboardCubit = DashboardCubit(dashboard)..load();
    _employeesCubit = EmployeesCubit(_employees, invitations: _invitations);
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
    _leaveRequestsCubit = LeaveRequestsCubit(_leaveRequests)..load();
    _profileCubit = ProfileCubit(
      _profile,
      onProfileChanged: widget.sessionCoordinator?.synchronizeProfile,
    );
    _managerShiftsCubit = ManagerShiftsCubit(_shifts);
    _managerAttendanceCubit = ManagerAttendanceCubit(_attendance);
    _employeeAttendanceCubit = EmployeeAttendanceCubit(_attendance);
    _employeeShiftsCubit = EmployeeShiftsCubit(
      _shifts,
      _attendance,
      onAttendanceChanged: () => _employeeAttendanceCubit.load(refresh: true),
    );
    final coordinator = widget.sessionCoordinator;
    if (coordinator == null) {
      _profileCubit.load();
      _employeesCubit.load();
      const previewScope = FeatureSessionScope(
        userId: 'preview-user',
        workspaceId: 'preview-workspace',
        timezone: 'Etc/UTC',
        role: WorkspaceRole.manager,
      );
      _managerShiftsCubit.bindSession(previewScope);
      _managerAttendanceCubit.bindSession(previewScope);
    } else {
      _sessionSubscription = coordinator.stream.listen(_bindSession);
      _bindSession(coordinator.state);
    }
  }

  @override
  void dispose() {
    _dashboardCubit.close();
    _employeesCubit.close();
    _workspacesCubit.close();
    _leaveRequestsCubit.close();
    _profileCubit.close();
    _managerShiftsCubit.close();
    _employeeShiftsCubit.close();
    _managerAttendanceCubit.close();
    _employeeAttendanceCubit.close();
    _sessionSubscription?.cancel();
    _sessionRefresh?.dispose();
    widget.sessionCoordinator?.close();
    if (widget.router == null) _router.dispose();
    super.dispose();
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
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider.value(value: _dashboardCubit),
          BlocProvider.value(value: _employeesCubit),
          BlocProvider.value(value: _workspacesCubit),
          BlocProvider.value(value: _leaveRequestsCubit),
          BlocProvider.value(value: _profileCubit),
          BlocProvider.value(value: _managerShiftsCubit),
          BlocProvider.value(value: _employeeShiftsCubit),
          BlocProvider.value(value: _managerAttendanceCubit),
          BlocProvider.value(value: _employeeAttendanceCubit),
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
    _employeeAttendanceCubit.bindSession(featureScope);
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
    timezone: membership.workspace.timezone,
    role: membership.role,
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
