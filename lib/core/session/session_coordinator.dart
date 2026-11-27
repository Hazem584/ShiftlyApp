import 'package:shiftly/core/models/manager_profile.dart';
import 'package:shiftly/core/session/profile_session_update.dart';
import 'package:shiftly/core/session/session_coordinator_cubit.dart';
import 'package:shiftly/core/session/session_registration_actions.dart';
import 'package:shiftly/core/session/session_resolution_actions.dart';
import 'package:shiftly/core/session/session_results.dart';
import 'package:shiftly/core/session/session_sign_in_actions.dart';
import 'package:shiftly/core/session/session_state.dart';
import 'package:shiftly/core/session/session_verification_actions.dart';
import 'package:shiftly/core/session/session_workspace_actions.dart';
import 'package:shiftly/core/session/workspace_exit_session.dart';
import 'package:shiftly/core/session/workspace_membership_policy.dart';
import 'package:shiftly/features/auth/domain/entities/current_user.dart';

export 'session_results.dart';

class SessionCoordinator extends SessionCoordinatorCubit {
  SessionCoordinator(
    super.authentication,
    super.repository,
    super.workspaceStorage,
  );

  Future<void> initialize() async {
    updateState(const SessionState.initializing());
    if (authentication.currentSession == null) {
      updateState(const SessionState(status: SessionStatus.unauthenticated));
      return;
    }
    await resolveSessionCurrentUser(this);
  }

  Future<void> signIn({required String email, required String password}) =>
      performSignIn(
        this,
        email: email,
        password: password,
        resolveUser: () => resolveSessionCurrentUser(this),
      );

  Future<void> signUp({required String email, required String password}) =>
      performSignUp(
        this,
        email: email,
        password: password,
        resolveUser: () => resolveSessionCurrentUser(this),
      );

  Future<bool> resendVerificationEmail() =>
      performResendVerificationEmail(this);

  Future<void> bootstrapProfile({String? fullName, String? phone}) =>
      performBootstrapProfile(
        this,
        fullName: fullName,
        phone: phone,
        resolveUser: () => resolveSessionCurrentUser(this),
      );

  Future<void> retry() async {
    if (authentication.currentSession == null) {
      updateState(const SessionState(status: SessionStatus.unauthenticated));
      return;
    }
    await resolveSessionCurrentUser(this);
  }

  Future<MembershipRefreshResult> refreshMemberships({
    required String preferredWorkspaceId,
    required String expectedUserId,
  }) async {
    if (authentication.currentSession == null) {
      updateState(const SessionState(status: SessionStatus.unauthenticated));
      return const MembershipRefreshResult.failed();
    }
    await resolveSessionCurrentUser(
      this,
      preferredWorkspaceId: preferredWorkspaceId,
    );
    return refreshedMembership(state, expectedUserId, preferredWorkspaceId);
  }

  List<WorkspaceMembership> get selectableMemberships =>
      activeWorkspaceMemberships(state.currentUser?.memberships ?? const []);

  Future<WorkspaceSwitchResult> selectWorkspace(String workspaceId) =>
      switchSessionWorkspace(this, workspaceId, requireAlternative: false);

  Future<WorkspaceSwitchResult> switchWorkspace(String workspaceId) =>
      switchSessionWorkspace(this, workspaceId, requireAlternative: true);

  Future<void> workspaceLeft(String workspaceId, String expectedUserId) =>
      handleWorkspaceLeft(this, workspaceId, expectedUserId);

  void synchronizeProfile(ManagerProfile profile) {
    final updated = sessionWithUpdatedProfile(state, profile);
    if (updated != null) updateState(updated);
  }

  Future<void> signOut() async {
    loggingOut = true;
    hasObservedSession = false;
    authenticationGeneration += 1;
    resolutionGeneration += 1;
    updateState(const SessionState(status: SessionStatus.unauthenticated));
    try {
      await authentication.signOut();
      await workspaceStorage.clear();
    } finally {
      loggingOut = false;
    }
  }
}
