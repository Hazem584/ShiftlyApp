import 'package:shiftly/core/session/session_coordinator.dart';
import 'package:shiftly/features/workspaces/domain/repositories/workspace_exit_repository.dart';
import 'package:shiftly/features/workspaces/domain/repositories/workspace_repository.dart';
import 'package:shiftly/features/workspaces/presentation/cubit/workspaces_state.dart';
import 'package:shiftly/features/workspaces/presentation/cubit/workspaces_tracker.dart';

Future<bool> leaveWorkspaceAction(
  WorkspacesTracker t,
  WorkspaceRepository repository,
  String workspaceId,
  String? confirmation,
  Future<void> Function(String, String)? onLeft,
  WorkspacesState Function() getState,
  void Function(WorkspacesState) emit,
  bool Function() isClosed,
) async {
  final user = t.userId, gen = t.generation;
  if (user == null ||
      t.leaveInFlight ||
      getState().busy ||
      repository is! WorkspaceExitRepository) {
    return false;
  }
  t.leaveInFlight = true;
  t.loadRevision++;
  emit(getState().copyWith(leaving: true, loading: false, clearFailure: true));
  try {
    await (repository as WorkspaceExitRepository).leaveWorkspace(
      workspaceId,
      confirmation: confirmation,
    );
    if (!t.current(isClosed(), user, gen)) return false;
    final list = getState().workspaces.where((w) => w.id != workspaceId);
    emit(getState().copyWith(workspaces: list.toList()));
    await onLeft?.call(workspaceId, user);
    return t.current(isClosed(), user, gen);
  } catch (e) {
    if (t.current(isClosed(), user, gen)) {
      emit(getState().copyWith(failure: workspacesFailure(e)));
    }
    return false;
  } finally {
    t.leaveInFlight = false;
    if (t.current(isClosed(), user, gen)) {
      emit(getState().copyWith(leaving: false));
    }
  }
}

Future<bool> createWorkspaceAction(
  WorkspacesTracker t,
  WorkspaceRepository repository,
  String name,
  String? timezone,
  Future<MembershipRefreshResult> Function(String, String) onRefresh,
  WorkspacesState Function() getState,
  void Function(WorkspacesState) emit,
  bool Function() isClosed,
) async {
  final user = t.userId, gen = t.generation;
  if (user == null || t.anyMutationInFlight) return false;
  t.createInFlight = true;
  emit(getState().copyWith(creating: true, clearFailure: true));
  try {
    final ws = await repository.createWorkspace(name: name, timezone: timezone);
    if (!t.current(isClosed(), user, gen)) return false;
    return await t.refreshMembership(
      expectedUser: user,
      workspaceId: ws.id,
      isClosed: isClosed,
      refresh: onRefresh,
    );
  } catch (e) {
    if (!isClosed() && t.userId == user) {
      emit(getState().copyWith(creating: false, failure: workspacesFailure(e)));
    }
    return false;
  } finally {
    t.createInFlight = false;
    if (!isClosed() && getState().creating) {
      emit(getState().copyWith(creating: false));
    }
  }
}
