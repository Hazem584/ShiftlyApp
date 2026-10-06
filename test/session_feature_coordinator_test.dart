import 'package:flutter_test/flutter_test.dart';
import 'package:shiftly/app/session_feature_coordinator.dart';
import 'package:shiftly/core/session/session_state.dart';
import 'package:shiftly/features/auth/data/models/current_user.dart';

SessionState _state({
  String userId = 'user-a',
  String workspaceId = 'workspace-a',
  String membershipId = 'membership-a',
  WorkspaceRole role = WorkspaceRole.manager,
  MembershipStatus membershipStatus = MembershipStatus.active,
  String profileName = 'Before refresh',
}) {
  final membership = WorkspaceMembership(
    id: membershipId,
    role: role,
    status: membershipStatus,
    workspace: Workspace(
      id: workspaceId,
      name: 'Workspace',
      code: 'CODE',
      timezone: 'Africa/Cairo',
    ),
  );
  return SessionState(
    status: role == WorkspaceRole.manager
        ? SessionStatus.authenticatedManager
        : SessionStatus.authenticatedEmployee,
    currentUser: CurrentUser(
      id: userId,
      fullName: profileName,
      createdAt: DateTime.utc(2026),
      updatedAt: DateTime.utc(2026, 10, 6),
      memberships: [membership],
    ),
    activeMembership: membership,
  );
}

void main() {
  test('equivalent authorized emissions retain the feature generation', () {
    final generations = <int>[];
    final coordinator = SessionFeatureCoordinator(
      (_, generation) => generations.add(generation),
    );
    coordinator.bind(_state());
    coordinator.bind(_state(profileName: 'Profile refreshed'));
    final transient = _state(profileName: 'Profile refreshed');
    coordinator.bind(
      SessionState(
        status: SessionStatus.loadingCurrentUser,
        currentUser: transient.currentUser,
        activeMembership: transient.activeMembership,
      ),
    );
    expect(generations, [1, 1, 1]);
  });

  test('security and ownership scope changes advance the generation', () {
    final generations = <int>[];
    final coordinator = SessionFeatureCoordinator(
      (_, generation) => generations.add(generation),
    );
    coordinator.bind(_state());
    coordinator.bind(_state(workspaceId: 'workspace-b'));
    coordinator.bind(_state(role: WorkspaceRole.employee));
    coordinator.bind(const SessionState(status: SessionStatus.unauthenticated));
    coordinator.bind(_state(userId: 'user-b'));
    expect(generations, [1, 2, 3, 4, 5]);
  });

  test('explicit invalidation always advances the generation', () {
    final generations = <int>[];
    final state = _state();
    final coordinator = SessionFeatureCoordinator(
      (_, generation) => generations.add(generation),
    );
    coordinator.bind(state);
    coordinator.invalidate(state);
    expect(generations, [1, 2]);
  });
}
