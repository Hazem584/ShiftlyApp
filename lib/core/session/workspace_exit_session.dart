import 'package:shiftly/core/session/session_results.dart';
import 'package:shiftly/core/session/session_state.dart';
import 'package:shiftly/features/auth/domain/entities/current_user.dart';

MembershipRefreshResult refreshedMembership(
  SessionState state,
  String userId,
  String workspaceId,
) {
  final membership = state.activeMembership;
  if (!state.isAuthenticated ||
      state.currentUser?.id != userId ||
      membership?.workspace.id != workspaceId ||
      membership?.status != MembershipStatus.active ||
      membership?.role == WorkspaceRole.unknown) {
    return const MembershipRefreshResult.failed();
  }
  return MembershipRefreshResult.authorized(
    userId: userId,
    workspaceId: workspaceId,
    role: membership!.role,
  );
}

SessionState sessionWithoutWorkspace(SessionState state, String id) {
  final old = state.currentUser!;
  final memberships = old.memberships
      .where((m) => m.workspace.id != id)
      .toList(growable: false);
  final user = CurrentUser(
    id: old.id,
    email: old.email,
    fullName: old.fullName,
    phone: old.phone,
    avatarUrl: old.avatarUrl,
    createdAt: old.createdAt,
    updatedAt: old.updatedAt,
    memberships: memberships,
  );
  final available = memberships
      .where(
        (m) =>
            m.status == MembershipStatus.active &&
            m.role != WorkspaceRole.unknown,
      )
      .toList();
  final selected = state.activeMembership?.workspace.id == id
      ? available.firstOrNull
      : state.activeMembership;
  if (selected == null) {
    return SessionState(
      status: SessionStatus.workspaceSelectionRequired,
      currentUser: user,
    );
  }
  return SessionState(
    status: selected.role == WorkspaceRole.manager
        ? SessionStatus.authenticatedManager
        : SessionStatus.authenticatedEmployee,
    currentUser: user,
    activeMembership: selected,
  );
}
