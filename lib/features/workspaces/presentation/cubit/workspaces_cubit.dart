import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/error/api_exception.dart';
import 'package:shiftly/core/error/failure.dart';
import 'package:shiftly/features/invitations/data/invitation_repository.dart';
import 'package:shiftly/features/workspaces/data/workspace_repository.dart';

class WorkspacesState extends Equatable {
  const WorkspacesState({
    this.loading = true,
    this.workspaces = const [],
    this.invitations = const [],
    this.creating = false,
    this.accepting = false,
    this.failure,
  });
  final bool loading;
  final List<WorkspaceRecord> workspaces;
  final List<WorkspaceInvitation> invitations;
  final bool creating;
  final bool accepting;
  final Failure? failure;

  WorkspacesState copyWith({
    bool? loading,
    List<WorkspaceRecord>? workspaces,
    List<WorkspaceInvitation>? invitations,
    bool? creating,
    bool? accepting,
    Failure? failure,
    bool clearFailure = false,
  }) => WorkspacesState(
    loading: loading ?? this.loading,
    workspaces: workspaces ?? this.workspaces,
    invitations: invitations ?? this.invitations,
    creating: creating ?? this.creating,
    accepting: accepting ?? this.accepting,
    failure: clearFailure ? null : failure ?? this.failure,
  );

  @override
  List<Object?> get props => [
    loading,
    workspaces,
    invitations,
    creating,
    accepting,
    failure,
  ];
}

class WorkspacesCubit extends Cubit<WorkspacesState> {
  WorkspacesCubit(
    this._workspaces,
    this._invitations, {
    required this.onMembershipChanged,
  }) : super(const WorkspacesState());
  final WorkspaceRepository _workspaces;
  final InvitationRepository _invitations;
  final Future<void> Function(String workspaceId) onMembershipChanged;
  String? _userId;
  var _generation = 0;

  void bindUser(String? userId) {
    if (_userId == userId) return;
    _userId = userId;
    _generation += 1;
    emit(const WorkspacesState());
    if (userId != null) unawaited(load());
  }

  Future<void> load() async {
    final userId = _userId;
    final generation = _generation;
    if (userId == null) return;
    emit(state.copyWith(loading: true, clearFailure: true));
    try {
      final results = await Future.wait<Object>([
        _workspaces.listWorkspaces(),
        _invitations.listMyInvitations(),
      ]);
      if (!_current(userId, generation)) return;
      emit(
        WorkspacesState(
          loading: false,
          workspaces: results[0] as List<WorkspaceRecord>,
          invitations: results[1] as List<WorkspaceInvitation>,
        ),
      );
    } catch (error) {
      if (!_current(userId, generation)) return;
      emit(state.copyWith(loading: false, failure: _failure(error)));
    }
  }

  Future<bool> create({required String name, String? timezone}) async {
    final userId = _userId;
    final generation = _generation;
    if (userId == null || state.creating) return false;
    emit(state.copyWith(creating: true, clearFailure: true));
    try {
      final workspace = await _workspaces.createWorkspace(
        name: name,
        timezone: timezone,
      );
      if (!_current(userId, generation)) return false;
      emit(state.copyWith(creating: false));
      await onMembershipChanged(workspace.id);
      return _current(userId, generation);
    } catch (error) {
      if (_current(userId, generation)) {
        emit(state.copyWith(creating: false, failure: _failure(error)));
      }
      return false;
    }
  }

  Future<bool> accept(String inviteToken) async {
    final userId = _userId;
    final generation = _generation;
    if (userId == null || state.accepting) return false;
    emit(state.copyWith(accepting: true, clearFailure: true));
    try {
      final workspace = await _invitations.acceptInvitation(inviteToken);
      if (!_current(userId, generation)) return false;
      emit(state.copyWith(accepting: false));
      await onMembershipChanged(workspace.id);
      return _current(userId, generation);
    } catch (error) {
      if (_current(userId, generation)) {
        emit(state.copyWith(accepting: false, failure: _failure(error)));
      }
      return false;
    }
  }

  Failure _failure(Object error) => error is ApiException
      ? error.toFailure()
      : const Failure(message: 'Unable to load workspace options.');
  bool _current(String userId, int generation) =>
      !isClosed && _userId == userId && _generation == generation;
}
