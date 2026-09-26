import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shiftly/core/constants/app_strings.dart';
import 'package:shiftly/core/routing/app_router.dart';
import 'package:shiftly/core/session/session_coordinator.dart';
import 'package:shiftly/core/session/session_state.dart';
import 'package:shiftly/core/theme/app_theme.dart';
import 'package:shiftly/features/attendance/data/leave_request_repository.dart';
import 'package:shiftly/features/attendance/data/mock_leave_request_repository.dart';
import 'package:shiftly/features/attendance/presentation/cubit/leave_requests_cubit.dart';
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
    _dashboardCubit = DashboardCubit(dashboard)..load();
    _employeesCubit = EmployeesCubit(_employees, invitations: _invitations);
    _workspacesCubit = WorkspacesCubit(
      _workspaces,
      _invitations,
      onMembershipChanged: (workspaceId) async => widget.sessionCoordinator
          ?.refreshMemberships(preferredWorkspaceId: workspaceId),
    );
    _leaveRequestsCubit = LeaveRequestsCubit(_leaveRequests)..load();
    _profileCubit = ProfileCubit(
      _profile,
      onProfileChanged: widget.sessionCoordinator?.synchronizeProfile,
    );
    final coordinator = widget.sessionCoordinator;
    if (coordinator == null) {
      _profileCubit.load();
      _employeesCubit.load();
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
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider.value(value: _dashboardCubit),
          BlocProvider.value(value: _employeesCubit),
          BlocProvider.value(value: _workspacesCubit),
          BlocProvider.value(value: _leaveRequestsCubit),
          BlocProvider.value(value: _profileCubit),
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
  }
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
