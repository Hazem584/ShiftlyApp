import 'package:shiftly/core/error/api_exception.dart';
import 'package:shiftly/core/error/failure.dart';
import 'package:shiftly/core/session/session_coordinator.dart';
import 'package:shiftly/features/workspaces/presentation/cubit/workspaces_state.dart';

class WorkspaceMembershipOperation {
  WorkspaceMembershipOperation(this.userId);
  final String userId;
  bool identityChanged = false;
}

class WorkspacesTracker {
  bool leaveInFlight = false;
  String? userId;
  int generation = 0;
  bool createInFlight = false;
  bool acceptInFlight = false;
  bool declineInFlight = false;
  int loadRevision = 0;
  final membershipOperations = <WorkspaceMembershipOperation>{};

  bool get anyMutationInFlight =>
      leaveInFlight || createInFlight || acceptInFlight || declineInFlight;

  WorkspacesState bindState(String? nextUserId) {
    if (nextUserId != null) {
      for (final operation in membershipOperations) {
        if (operation.userId != nextUserId) operation.identityChanged = true;
      }
    }
    userId = nextUserId;
    generation += 1;
    loadRevision++;
    return WorkspacesState(
      leaving: leaveInFlight,
      creating: createInFlight,
      accepting: acceptInFlight,
      declining: declineInFlight,
    );
  }

  bool current(bool isClosed, String expectedUser, int expectedGen) =>
      !isClosed && userId == expectedUser && generation == expectedGen;

  Future<bool> refreshMembership({
    required String expectedUser,
    required String workspaceId,
    required bool Function() isClosed,
    required Future<MembershipRefreshResult> Function(String, String) refresh,
  }) async {
    final op = WorkspaceMembershipOperation(expectedUser);
    membershipOperations.add(op);
    try {
      final res = await refresh(workspaceId, expectedUser);
      return !isClosed() &&
          !op.identityChanged &&
          (userId == null || userId == op.userId) &&
          res.authorizes(userId: op.userId, workspaceId: workspaceId);
    } finally {
      membershipOperations.remove(op);
    }
  }
}

Failure workspacesFailure(Object error) => error is ApiException
    ? error.toFailure()
    : const Failure(message: 'Unable to load workspace options.');
