import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/session/session_coordinator.dart';
import 'package:shiftly/features/invitations/domain/repositories/invitation_repository.dart';
import 'package:shiftly/features/workspaces/domain/repositories/workspace_exit_repository.dart';
import 'package:shiftly/features/workspaces/domain/repositories/workspace_repository.dart';
import 'package:shiftly/features/workspaces/presentation/cubit/workspaces_invitation_actions.dart';
import 'package:shiftly/features/workspaces/presentation/cubit/workspaces_load_action.dart';
import 'package:shiftly/features/workspaces/presentation/cubit/workspaces_state.dart';
import 'package:shiftly/features/workspaces/presentation/cubit/workspaces_tracker.dart';
import 'package:shiftly/features/workspaces/presentation/cubit/workspaces_workspace_actions.dart';

export 'workspaces_state.dart';

class WorkspacesCubit extends Cubit<WorkspacesState> {
  WorkspacesCubit(
    this._workspaces,
    this._invitations, {
    required this.onMembershipChanged,
    this.onWorkspaceLeft,
  }) : super(const WorkspacesState());

  final WorkspaceRepository _workspaces;
  final InvitationRepository _invitations;
  final Future<MembershipRefreshResult> Function(String, String)
  onMembershipChanged;
  final Future<void> Function(String workspaceId, String userId)?
  onWorkspaceLeft;
  final _t = WorkspacesTracker();

  bool get canLeave => _workspaces is WorkspaceExitRepository;
  WorkspacesState _state() => state;
  bool _closed() => isClosed;

  void bindUser(String? userId) {
    if (_t.userId == userId) return;
    emit(_t.bindState(userId));
    if (userId != null) unawaited(load());
  }

  Future<void> load() =>
      loadWorkspacesData(_t, _workspaces, _invitations, _state, emit, _closed);

  Future<bool> leave(String workspaceId, {String? confirmation}) =>
      leaveWorkspaceAction(
        _t,
        _workspaces,
        workspaceId,
        confirmation,
        onWorkspaceLeft,
        _state,
        emit,
        _closed,
      );

  Future<bool> create({required String name, String? timezone}) =>
      createWorkspaceAction(
        _t,
        _workspaces,
        name,
        timezone,
        onMembershipChanged,
        _state,
        emit,
        _closed,
      );

  Future<bool> accept(String inviteToken) => acceptWorkspaceInvitation(
    _t,
    () => _invitations.acceptInvitation(inviteToken.trim()),
    null,
    onMembershipChanged,
    _state,
    emit,
    _closed,
  );

  Future<bool> acceptById(String invitationId) => acceptWorkspaceInvitation(
    _t,
    () => _invitations.acceptInvitationById(invitationId),
    invitationId,
    onMembershipChanged,
    _state,
    emit,
    _closed,
  );

  Future<bool> decline(String invitationId) => declineWorkspaceInvitation(
    _t,
    _invitations,
    invitationId,
    _state,
    emit,
    _closed,
  );
}
