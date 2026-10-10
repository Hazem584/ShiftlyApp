import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/error/api_exception.dart';
import 'package:shiftly/core/error/failure.dart';
import 'package:shiftly/core/session/session_coordinator.dart';
import 'package:shiftly/features/invitations/domain/repositories/invitation_repository.dart';
import 'package:shiftly/features/workspaces/domain/repositories/workspace_repository.dart';

class WorkspacesState extends Equatable {
  const WorkspacesState({
    this.loading = true,
    this.workspaces = const [],
    this.invitations = const [],
    this.creating = false,
    this.accepting = false,
    this.declining = false,
    this.respondingInvitationId,
    this.failure,
  });
  final bool loading;
  final List<WorkspaceRecord> workspaces;
  final List<WorkspaceInvitation> invitations;
  final bool creating;
  final bool accepting;
  final bool declining;
  final String? respondingInvitationId;
  bool get busy => creating || accepting || declining;
  final Failure? failure;

  WorkspacesState copyWith({
    bool? loading,
    List<WorkspaceRecord>? workspaces,
    List<WorkspaceInvitation>? invitations,
    bool? creating,
    bool? accepting,
    bool? declining,
    String? respondingInvitationId,
    bool clearResponding = false,
    Failure? failure,
    bool clearFailure = false,
  }) => WorkspacesState(
    loading: loading ?? this.loading,
    workspaces: workspaces ?? this.workspaces,
    invitations: invitations ?? this.invitations,
    creating: creating ?? this.creating,
    accepting: accepting ?? this.accepting,
    declining: declining ?? this.declining,
    respondingInvitationId: clearResponding
        ? null
        : respondingInvitationId ?? this.respondingInvitationId,
    failure: clearFailure ? null : failure ?? this.failure,
  );

  @override
  List<Object?> get props => [
    loading,
    workspaces,
    invitations,
    creating,
    accepting,
    declining,
    respondingInvitationId,
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
  final Future<MembershipRefreshResult> Function(
    String workspaceId,
    String expectedUserId,
  )
  onMembershipChanged;
  String? _userId;
  var _generation = 0;
  var _createInFlight = false;
  var _acceptInFlight = false;
  var _declineInFlight = false;
  var _loadRevision = 0;
  final _membershipOperations = <_MembershipOperation>{};

  void bindUser(String? userId) {
    if (_userId == userId) return;
    if (userId != null) {
      for (final operation in _membershipOperations) {
        if (operation.userId != userId) operation.identityChanged = true;
      }
    }
    _userId = userId;
    _generation += 1;
    _loadRevision++;
    emit(
      WorkspacesState(
        creating: _createInFlight,
        accepting: _acceptInFlight,
        declining: _declineInFlight,
      ),
    );
    if (userId != null) unawaited(load());
  }

  Future<void> load() async {
    final userId = _userId;
    final generation = _generation;
    final revision = ++_loadRevision;
    if (userId == null) return;
    emit(state.copyWith(loading: true, clearFailure: true));
    try {
      final results = await Future.wait<Object>([
        _workspaces.listWorkspaces(),
        _invitations.listMyInvitations(),
      ]);
      if (!_current(userId, generation) || revision != _loadRevision) return;
      emit(
        WorkspacesState(
          loading: false,
          workspaces: results[0] as List<WorkspaceRecord>,
          invitations: results[1] as List<WorkspaceInvitation>,
          creating: _createInFlight,
          accepting: _acceptInFlight,
          declining: _declineInFlight,
          respondingInvitationId: state.respondingInvitationId,
        ),
      );
    } catch (error) {
      if (!_current(userId, generation) || revision != _loadRevision) return;
      emit(state.copyWith(loading: false, failure: _failure(error)));
    }
  }

  Future<bool> create({required String name, String? timezone}) async {
    final userId = _userId;
    final generation = _generation;
    if (userId == null ||
        _createInFlight ||
        _acceptInFlight ||
        _declineInFlight) {
      return false;
    }
    _createInFlight = true;
    emit(state.copyWith(creating: true, clearFailure: true));
    try {
      final workspace = await _workspaces.createWorkspace(
        name: name,
        timezone: timezone,
      );
      if (!_current(userId, generation)) return false;
      final operation = _MembershipOperation(userId);
      _membershipOperations.add(operation);
      try {
        final result = await onMembershipChanged(workspace.id, userId);
        return _membershipRefreshSucceeded(operation, result, workspace.id);
      } finally {
        _membershipOperations.remove(operation);
      }
    } catch (error) {
      if (!isClosed && _userId == userId) {
        emit(state.copyWith(creating: false, failure: _failure(error)));
      }
      return false;
    } finally {
      _createInFlight = false;
      if (!isClosed && state.creating) {
        emit(state.copyWith(creating: false));
      }
    }
  }

  Future<bool> accept(String inviteToken) =>
      _accept(() => _invitations.acceptInvitation(inviteToken.trim()));

  Future<bool> acceptById(String invitationId) => _accept(
    () => _invitations.acceptInvitationById(invitationId),
    invitationId: invitationId,
  );

  Future<bool> _accept(
    Future<WorkspaceRecord> Function() request, {
    String? invitationId,
  }) async {
    final userId = _userId;
    final generation = _generation;
    if (userId == null ||
        _acceptInFlight ||
        _declineInFlight ||
        _createInFlight) {
      return false;
    }
    _acceptInFlight = true;
    _loadRevision++;
    emit(
      state.copyWith(
        loading: false,
        accepting: true,
        respondingInvitationId: invitationId,
        clearFailure: true,
      ),
    );
    try {
      final workspace = await request();
      if (!_current(userId, generation)) return false;
      final operation = _MembershipOperation(userId);
      _membershipOperations.add(operation);
      try {
        final result = await onMembershipChanged(workspace.id, userId);
        return _membershipRefreshSucceeded(operation, result, workspace.id);
      } finally {
        _membershipOperations.remove(operation);
      }
    } catch (error) {
      if (!isClosed && _userId == userId) {
        emit(state.copyWith(accepting: false, failure: _failure(error)));
      }
      return false;
    } finally {
      _acceptInFlight = false;
      if (!isClosed) {
        emit(state.copyWith(accepting: false, clearResponding: true));
      }
    }
  }

  Future<bool> decline(String invitationId) async {
    final userId = _userId;
    final generation = _generation;
    if (userId == null ||
        _acceptInFlight ||
        _declineInFlight ||
        _createInFlight) {
      return false;
    }
    _declineInFlight = true;
    _loadRevision++;
    emit(
      state.copyWith(
        loading: false,
        declining: true,
        respondingInvitationId: invitationId,
        clearFailure: true,
      ),
    );
    try {
      await _invitations.declineInvitation(invitationId);
      if (!_current(userId, generation)) return false;
      _loadRevision++;
      emit(
        state.copyWith(
          invitations: state.invitations
              .where((item) => item.id != invitationId)
              .toList(growable: false),
        ),
      );
      return true;
    } catch (error) {
      if (_current(userId, generation)) {
        emit(state.copyWith(failure: _failure(error)));
      }
      return false;
    } finally {
      _declineInFlight = false;
      if (!isClosed && state.declining) {
        emit(state.copyWith(declining: false, clearResponding: true));
      }
    }
  }

  bool _membershipRefreshSucceeded(
    _MembershipOperation operation,
    MembershipRefreshResult result,
    String workspaceId,
  ) =>
      !isClosed &&
      !operation.identityChanged &&
      (_userId == null || _userId == operation.userId) &&
      result.authorizes(userId: operation.userId, workspaceId: workspaceId);

  Failure _failure(Object error) => error is ApiException
      ? error.toFailure()
      : const Failure(message: 'Unable to load workspace options.');
  bool _current(String userId, int generation) =>
      !isClosed && _userId == userId && _generation == generation;
}

class _MembershipOperation {
  _MembershipOperation(this.userId);

  final String userId;
  bool identityChanged = false;
}
