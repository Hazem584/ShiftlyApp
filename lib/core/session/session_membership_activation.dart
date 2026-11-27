import 'package:shiftly/core/error/api_exception.dart';
import 'package:shiftly/core/error/failure.dart';
import 'package:shiftly/core/session/session_coordinator_cubit.dart';
import 'package:shiftly/core/session/session_state.dart';
import 'package:shiftly/features/auth/domain/entities/current_user.dart';

Future<void> handleSessionResolutionError(
  SessionCoordinatorCubit cubit,
  ApiException error,
) async {
  if (error.code == 'PROFILE_NOT_INITIALIZED') {
    cubit.updateState(
      const SessionState(status: SessionStatus.profileSetupRequired),
    );
  } else if (error.kind == FailureKind.network ||
      error.kind == FailureKind.timeout) {
    cubit.updateState(
      SessionState(
        status: SessionStatus.offlineWithSession,
        failure: error.toFailure(),
      ),
    );
  } else if (error.statusCode == 401) {
    cubit.loggingOut = true;
    cubit.hasObservedSession = false;
    cubit.resolutionGeneration += 1;
    try {
      if (cubit.authentication.currentSession != null) {
        await cubit.authentication.signOut();
      }
      await cubit.workspaceStorage.clear();
    } finally {
      cubit.loggingOut = false;
    }
    cubit.updateState(const SessionState(status: SessionStatus.sessionExpired));
    cubit.updateState(const SessionState.expired());
  } else {
    cubit.updateState(
      SessionState(status: SessionStatus.failure, failure: error.toFailure()),
    );
  }
}

Future<void> activateSessionMembership(
  SessionCoordinatorCubit cubit,
  CurrentUser user,
  WorkspaceMembership membership, {
  int? resolutionGeneration,
}) async {
  if (resolutionGeneration != null &&
      !cubit.resolutionIsCurrent(resolutionGeneration)) {
    return;
  }
  await cubit.workspaceStorage.write(membership.workspace.id);
  if (resolutionGeneration != null &&
      !cubit.resolutionIsCurrent(resolutionGeneration)) {
    await cubit.workspaceStorage.clear();
    return;
  }
  cubit.updateState(
    SessionState(
      status: membership.role == WorkspaceRole.manager
          ? SessionStatus.authenticatedManager
          : SessionStatus.authenticatedEmployee,
      currentUser: user,
      activeMembership: membership,
    ),
  );
}
