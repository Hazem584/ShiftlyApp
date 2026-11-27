import 'package:shiftly/core/error/api_exception.dart';
import 'package:shiftly/core/session/session_coordinator_cubit.dart';
import 'package:shiftly/core/session/session_membership_activation.dart';
import 'package:shiftly/core/session/session_state.dart';
import 'package:shiftly/core/session/workspace_membership_policy.dart';

export 'session_membership_activation.dart';

Future<void> resolveSessionCurrentUser(
  SessionCoordinatorCubit cubit, {
  String? preferredWorkspaceId,
}) async {
  if (cubit.resolving) return;
  cubit.hasObservedSession = true;
  cubit.resolving = true;
  final generation = ++cubit.resolutionGeneration;
  cubit.updateState(
    const SessionState(status: SessionStatus.loadingCurrentUser),
  );
  try {
    final user = await cubit.repository.loadCurrentUser();
    if (!cubit.resolutionIsCurrent(generation)) return;
    final memberships = activeWorkspaceMemberships(user.memberships);
    final savedId =
        preferredWorkspaceId ?? await cubit.workspaceStorage.read();
    if (!cubit.resolutionIsCurrent(generation)) return;
    if (memberships.isEmpty) {
      await cubit.workspaceStorage.clear();
      if (!cubit.resolutionIsCurrent(generation)) return;
      cubit.updateState(
        SessionState(
          status: SessionStatus.workspaceSelectionRequired,
          currentUser: user,
        ),
      );
    } else if (memberships.length == 1) {
      await activateSessionMembership(
        cubit,
        user,
        memberships.single,
        resolutionGeneration: generation,
      );
    } else {
      final restored = memberships.where((m) => m.workspace.id == savedId);
      if (restored.length == 1) {
        await activateSessionMembership(
          cubit,
          user,
          restored.single,
          resolutionGeneration: generation,
        );
      } else {
        if (savedId != null) await cubit.workspaceStorage.clear();
        if (!cubit.resolutionIsCurrent(generation)) return;
        cubit.updateState(
          SessionState(
            status: SessionStatus.workspaceSelectionRequired,
            currentUser: user,
          ),
        );
      }
    }
  } on ApiException catch (error) {
    if (!cubit.resolutionIsCurrent(generation)) return;
    await handleSessionResolutionError(cubit, error);
  } finally {
    cubit.resolving = false;
  }
}
