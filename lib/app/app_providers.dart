import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:shiftly/core/constants/app_strings.dart';
import 'package:shiftly/app/session_feature_coordinator.dart';
import 'package:shiftly/app/app_lifecycle_listener.dart';
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
import 'package:shiftly/features/fixed_shifts/data/fixed_shift_repository.dart';
import 'package:shiftly/features/fixed_shifts/data/preview_fixed_shift_repository.dart';
import 'package:shiftly/features/fixed_shifts/presentation/cubit/fixed_shifts_cubit.dart';
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

part 'parts/app_providers/private_app_providers_state.dart';
part 'parts/app_providers/private_session_router_refresh.dart';

class AppProviders extends StatefulWidget {
  const AppProviders({
    super.key,
    this.locator,
    this.preview = false,
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
    this.fixedShiftRepository,
  });

  /// Supplying a locator selects authenticated production composition.
  /// Omitting it preserves the explicit preview/test composition API.
  final GetIt? locator;
  final bool preview;

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
  final FixedShiftRepository? fixedShiftRepository;

  @override
  State<AppProviders> createState() => _AppProvidersState();
}

FeatureSessionScope? _featureScope(SessionState state, int generation) {
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
    membershipStatus: membership.status,
    generation: generation,
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
