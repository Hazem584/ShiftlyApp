import 'package:shiftly/core/session/session_coordinator.dart';
import 'package:shiftly/features/invitations/domain/repositories/invitation_repository.dart';
import 'package:shiftly/features/workspaces/domain/repositories/workspace_repository.dart';
import 'package:shiftly/features/workspaces/presentation/cubit/workspaces_state.dart';
import 'package:shiftly/features/workspaces/presentation/cubit/workspaces_tracker.dart';

Future<bool> acceptWorkspaceInvitation(
  WorkspacesTracker t,
  Future<WorkspaceRecord> Function() request,
  String? invitationId,
  Future<MembershipRefreshResult> Function(String, String) onRefresh,
  WorkspacesState Function() getState,
  void Function(WorkspacesState) emit,
  bool Function() isClosed,
) async {
  final user = t.userId, gen = t.generation;
  if (user == null || t.anyMutationInFlight) return false;
  t.acceptInFlight = true;
  t.loadRevision++;
  emit(
    getState().copyWith(
      loading: false,
      accepting: true,
      respondingInvitationId: invitationId,
      clearFailure: true,
    ),
  );
  try {
    final ws = await request();
    if (!t.current(isClosed(), user, gen)) return false;
    return await t.refreshMembership(
      expectedUser: user,
      workspaceId: ws.id,
      isClosed: isClosed,
      refresh: onRefresh,
    );
  } catch (e) {
    if (!isClosed() && t.userId == user) {
      emit(
        getState().copyWith(accepting: false, failure: workspacesFailure(e)),
      );
    }
    return false;
  } finally {
    t.acceptInFlight = false;
    if (!isClosed()) {
      emit(getState().copyWith(accepting: false, clearResponding: true));
    }
  }
}

Future<bool> declineWorkspaceInvitation(
  WorkspacesTracker t,
  InvitationRepository invitations,
  String invitationId,
  WorkspacesState Function() getState,
  void Function(WorkspacesState) emit,
  bool Function() isClosed,
) async {
  final user = t.userId, gen = t.generation;
  if (user == null || t.anyMutationInFlight) return false;
  t.declineInFlight = true;
  t.loadRevision++;
  emit(
    getState().copyWith(
      loading: false,
      declining: true,
      respondingInvitationId: invitationId,
      clearFailure: true,
    ),
  );
  try {
    await invitations.declineInvitation(invitationId);
    if (!t.current(isClosed(), user, gen)) return false;
    t.loadRevision++;
    final remaining = getState().invitations
        .where((i) => i.id != invitationId)
        .toList(growable: false);
    emit(getState().copyWith(invitations: remaining));
    return true;
  } catch (e) {
    if (t.current(isClosed(), user, gen)) {
      emit(getState().copyWith(failure: workspacesFailure(e)));
    }
    return false;
  } finally {
    t.declineInFlight = false;
    if (!isClosed() && getState().declining) {
      emit(getState().copyWith(declining: false, clearResponding: true));
    }
  }
}
