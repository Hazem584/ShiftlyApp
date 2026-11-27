import 'package:shiftly/features/invitations/domain/repositories/invitation_repository.dart';
import 'package:shiftly/features/workspaces/domain/repositories/workspace_repository.dart';
import 'package:shiftly/features/workspaces/presentation/cubit/workspaces_state.dart';
import 'package:shiftly/features/workspaces/presentation/cubit/workspaces_tracker.dart';

Future<void> loadWorkspacesData(
  WorkspacesTracker t,
  WorkspaceRepository workspaces,
  InvitationRepository invitations,
  WorkspacesState Function() getState,
  void Function(WorkspacesState) emit,
  bool Function() isClosed,
) async {
  final user = t.userId, gen = t.generation, rev = ++t.loadRevision;
  if (user == null) return;
  emit(getState().copyWith(loading: true, clearFailure: true));
  try {
    final res = await Future.wait<Object>([
      workspaces.listWorkspaces(),
      invitations.listMyInvitations(),
    ]);
    if (!t.current(isClosed(), user, gen) || rev != t.loadRevision) return;
    emit(
      WorkspacesState(
        loading: false,
        workspaces: res[0] as List<WorkspaceRecord>,
        invitations: res[1] as List<WorkspaceInvitation>,
        leaving: t.leaveInFlight,
        creating: t.createInFlight,
        accepting: t.acceptInFlight,
        declining: t.declineInFlight,
        respondingInvitationId: getState().respondingInvitationId,
      ),
    );
  } catch (e) {
    if (!t.current(isClosed(), user, gen) || rev != t.loadRevision) return;
    emit(getState().copyWith(loading: false, failure: workspacesFailure(e)));
  }
}
