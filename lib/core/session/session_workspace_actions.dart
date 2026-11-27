import 'package:shiftly/core/session/session_coordinator_cubit.dart';
import 'package:shiftly/core/session/session_resolution_actions.dart';
import 'package:shiftly/core/session/session_results.dart';
import 'package:shiftly/core/session/session_state.dart';
import 'package:shiftly/core/session/workspace_exit_session.dart';
import 'package:shiftly/core/session/workspace_membership_policy.dart';

Future<WorkspaceSwitchResult> switchSessionWorkspace(
  SessionCoordinatorCubit cubit,
  String workspaceId, {
  required bool requireAlternative,
}) async {
  if (cubit.switchingWorkspace) return WorkspaceSwitchResult.busy;
  final user = cubit.state.currentUser;
  if (user == null || cubit.authentication.currentSession == null) {
    return WorkspaceSwitchResult.invalid;
  }
  final memberships = activeWorkspaceMemberships(user.memberships);
  final currentId = cubit.state.activeMembership?.workspace.id;
  final alternatives = memberships.where((m) => m.workspace.id != currentId);
  if (requireAlternative && alternatives.isEmpty) {
    return WorkspaceSwitchResult.noAlternative;
  }
  final matches = memberships.where(
    (m) => m.workspace.id == workspaceId && m.workspace.id != currentId,
  );
  if (matches.length != 1) return WorkspaceSwitchResult.invalid;
  final previous = cubit.state;
  final generation = ++cubit.resolutionGeneration;
  cubit.switchingWorkspace = true;
  cubit.updateState(
    SessionState(status: SessionStatus.loadingCurrentUser, currentUser: user),
  );
  try {
    await activateSessionMembership(
      cubit,
      user,
      matches.single,
      resolutionGeneration: generation,
    );
    return cubit.resolutionIsCurrent(generation) &&
            cubit.state.activeMembership?.workspace.id == workspaceId
        ? WorkspaceSwitchResult.success
        : WorkspaceSwitchResult.invalid;
  } catch (_) {
    if (cubit.resolutionIsCurrent(generation)) cubit.updateState(previous);
    return WorkspaceSwitchResult.failure;
  } finally {
    cubit.switchingWorkspace = false;
  }
}

Future<void> handleWorkspaceLeft(
  SessionCoordinatorCubit cubit,
  String workspaceId,
  String expectedUserId,
) async {
  if (cubit.state.currentUser?.id != expectedUserId) return;
  cubit.resolutionGeneration++;
  final next = sessionWithoutWorkspace(cubit.state, workspaceId);
  cubit.updateState(next);
  if (next.activeMembership case final membership?) {
    await cubit.workspaceStorage.write(membership.workspace.id);
  } else {
    await cubit.workspaceStorage.clear();
  }
}
