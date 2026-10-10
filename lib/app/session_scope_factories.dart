import 'package:shiftly/core/session/feature_scope.dart';
import 'package:shiftly/core/session/session_state.dart';
import 'package:shiftly/features/auth/domain/entities/current_user.dart';
import 'package:shiftly/features/employees/presentation/cubit/employees_cubit.dart';
import 'package:shiftly/features/profile/presentation/cubit/profile_cubit.dart';

FeatureSessionScope? featureScopeForSession(
  SessionState state,
  int generation,
) {
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

ProfileSessionScope? profileScopeForSession(SessionState state) {
  final user = state.currentUser;
  final membership = state.activeMembership;
  if (!state.isAuthenticated || user == null || membership == null) return null;
  return ProfileSessionScope(
    userId: user.id,
    workspaceId: membership.workspace.id,
  );
}

EmployeeSessionScope? employeeScopeForSession(SessionState state) {
  final user = state.currentUser;
  final membership = state.activeMembership;
  if (!state.isAuthenticated || user == null || membership == null) return null;
  return EmployeeSessionScope(
    userId: user.id,
    workspaceId: membership.workspace.id,
    role: membership.role,
  );
}
