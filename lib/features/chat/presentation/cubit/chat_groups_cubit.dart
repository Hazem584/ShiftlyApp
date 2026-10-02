import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/error/api_exception.dart';
import 'package:shiftly/core/error/failure.dart';
import 'package:shiftly/core/session/feature_scope.dart';
import 'package:shiftly/features/chat/data/chat_models.dart';
import 'package:shiftly/features/chat/data/chat_repository.dart';

class ChatGroupsState extends Equatable {
  const ChatGroupsState({
    this.loading = true,
    this.groups = const [],
    this.unreadCount = 0,
    this.refreshing = false,
    this.mutating = false,
    this.failure,
  });

  final bool loading;
  final List<ChatGroup> groups;
  final int unreadCount;
  final bool refreshing;
  final bool mutating;
  final Failure? failure;

  ChatGroupsState copyWith({
    bool? loading,
    List<ChatGroup>? groups,
    int? unreadCount,
    bool? refreshing,
    bool? mutating,
    Failure? failure,
    bool clearFailure = false,
  }) => ChatGroupsState(
    loading: loading ?? this.loading,
    groups: groups ?? this.groups,
    unreadCount: unreadCount ?? this.unreadCount,
    refreshing: refreshing ?? this.refreshing,
    mutating: mutating ?? this.mutating,
    failure: clearFailure ? null : failure ?? this.failure,
  );

  @override
  List<Object?> get props => [
    loading,
    groups,
    unreadCount,
    refreshing,
    mutating,
    failure,
  ];
}

enum ChatMutationResult { success, failure, busy, stale }

class ChatGroupsCubit extends Cubit<ChatGroupsState> {
  ChatGroupsCubit(this._repository) : super(const ChatGroupsState());
  final ChatRepository _repository;
  FeatureSessionScope? _scope;
  var _generation = 0;
  var _request = 0;
  bool _loading = false;
  bool _refreshQueued = false;
  bool _unreadRefreshing = false;
  bool _unreadRefreshQueued = false;
  var _unreadRequest = 0;
  var _unreadIssuedSequence = 0;
  var _unreadAppliedSequence = 0;

  FeatureSessionScope? get scope => _scope;

  void bindSession(FeatureSessionScope? scope) {
    final authorized = scope?.isManager == true || scope?.isEmployee == true
        ? scope
        : null;
    if (_scope == authorized) return;
    _scope = authorized;
    _generation++;
    _request++;
    _loading = false;
    _refreshQueued = false;
    _unreadRefreshing = false;
    _unreadRefreshQueued = false;
    _unreadRequest++;
    _unreadIssuedSequence = 0;
    _unreadAppliedSequence = 0;
    emit(const ChatGroupsState());
    if (authorized != null) unawaited(load());
  }

  Future<void> load({bool refresh = false}) async {
    final scope = _scope;
    if (scope == null) return;
    if (_loading) {
      if (refresh) _refreshQueued = true;
      return;
    }
    _loading = true;
    final generation = _generation;
    final request = ++_request;
    final unreadSequence = ++_unreadIssuedSequence;
    final previous = state;
    emit(
      refresh && previous.groups.isNotEmpty
          ? previous.copyWith(refreshing: true, clearFailure: true)
          : ChatGroupsState(unreadCount: previous.unreadCount),
    );
    try {
      final results = await Future.wait<Object>([
        _repository.listGroups(scope.workspaceId),
        _repository.unreadCount(scope.workspaceId),
      ]);
      if (!_current(scope, generation, request)) return;
      final groups = results[0] as List<ChatGroup>;
      if (groups.any((group) => group.workspaceId != scope.workspaceId)) {
        throw const FormatException('Cross-workspace chat response');
      }
      emit(
        ChatGroupsState(
          loading: false,
          groups: groups,
          unreadCount: _acceptUnreadResult(scope, generation, unreadSequence)
              ? results[1] as int
              : state.unreadCount,
        ),
      );
    } catch (error) {
      if (!_current(scope, generation, request)) return;
      final failure = _failure(error, 'Unable to load chat groups.');
      emit(
        state.copyWith(
          loading: false,
          groups: previous.groups,
          refreshing: false,
          failure: failure,
        ),
      );
    } finally {
      if (_scopeCurrent(scope, generation)) {
        _loading = false;
        if (_refreshQueued) {
          _refreshQueued = false;
          unawaited(load(refresh: true));
        }
      }
    }
  }

  Future<void> refreshUnread() async {
    final scope = _scope;
    if (scope == null) return;
    if (_unreadRefreshing) {
      _unreadRefreshQueued = true;
      return;
    }
    _unreadRefreshing = true;
    final generation = _generation;
    final request = ++_unreadRequest;
    final unreadSequence = ++_unreadIssuedSequence;
    try {
      final value = await _repository.unreadCount(scope.workspaceId);
      if (_unreadCurrent(scope, generation, request) &&
          _acceptUnreadResult(scope, generation, unreadSequence)) {
        emit(state.copyWith(unreadCount: value));
      }
    } catch (_) {
      // Background badge refreshes preserve the last canonical count.
    } finally {
      if (_unreadCurrent(scope, generation, request)) {
        _unreadRefreshing = false;
        if (_unreadRefreshQueued) {
          _unreadRefreshQueued = false;
          unawaited(refreshUnread());
        }
      }
    }
  }

  Future<ChatMutationResult> create({
    required String name,
    String? description,
    required List<String> membershipIds,
  }) => _mutate(
    (scope) => _repository.createGroup(
      scope.workspaceId,
      name: name,
      description: description,
      memberMembershipIds: membershipIds,
    ),
  );

  Future<ChatMutationResult> update(
    String groupId, {
    required String name,
    String? description,
  }) => _mutate(
    (scope) => _repository.updateGroup(
      scope.workspaceId,
      groupId,
      name: name,
      description: description,
    ),
  );

  Future<ChatMutationResult> archive(String groupId) =>
      _mutate((scope) => _repository.archiveGroup(scope.workspaceId, groupId));

  Future<ChatMutationResult> _mutate(
    Future<Object?> Function(FeatureSessionScope scope) operation,
  ) async {
    final scope = _scope;
    if (scope == null || !scope.isManager) return ChatMutationResult.failure;
    if (state.mutating) return ChatMutationResult.busy;
    final generation = _generation;
    emit(state.copyWith(mutating: true, clearFailure: true));
    try {
      await operation(scope);
      if (!_scopeCurrent(scope, generation)) return ChatMutationResult.stale;
      emit(state.copyWith(mutating: false));
      await _refreshAfterMutation(scope, generation);
      return _scopeCurrent(scope, generation)
          ? ChatMutationResult.success
          : ChatMutationResult.stale;
    } catch (error) {
      if (!_scopeCurrent(scope, generation)) return ChatMutationResult.stale;
      emit(
        state.copyWith(
          mutating: false,
          failure: _failure(error, 'Unable to update the chat group.'),
        ),
      );
      return ChatMutationResult.failure;
    }
  }

  Future<void> _refreshAfterMutation(
    FeatureSessionScope scope,
    int generation,
  ) async {
    final request = ++_request;
    final unreadSequence = ++_unreadIssuedSequence;
    try {
      final results = await Future.wait<Object>([
        _repository.listGroups(scope.workspaceId),
        _repository.unreadCount(scope.workspaceId),
      ]);
      if (!_current(scope, generation, request)) return;
      final groups = results[0] as List<ChatGroup>;
      if (groups.any((group) => group.workspaceId != scope.workspaceId)) {
        throw const FormatException('Cross-workspace chat response');
      }
      emit(
        state.copyWith(
          groups: groups,
          unreadCount: _acceptUnreadResult(scope, generation, unreadSequence)
              ? results[1] as int
              : state.unreadCount,
          clearFailure: true,
        ),
      );
    } catch (error) {
      if (_current(scope, generation, request)) {
        emit(
          state.copyWith(
            failure: _failure(
              error,
              'The change was saved, but chat could not be refreshed.',
            ),
          ),
        );
      }
    }
  }

  Failure _failure(Object error, String fallback) => error is ApiException
      ? error.toFailure()
      : Failure(message: fallback, kind: FailureKind.server);
  bool _current(FeatureSessionScope scope, int generation, int request) =>
      _scopeCurrent(scope, generation) && _request == request;
  bool _scopeCurrent(FeatureSessionScope scope, int generation) =>
      !isClosed && _scope == scope && _generation == generation;
  bool _unreadCurrent(FeatureSessionScope scope, int generation, int request) =>
      _scopeCurrent(scope, generation) && _unreadRequest == request;
  bool _acceptUnreadResult(
    FeatureSessionScope scope,
    int generation,
    int sequence,
  ) {
    if (!_scopeCurrent(scope, generation) ||
        sequence < _unreadAppliedSequence) {
      return false;
    }
    _unreadAppliedSequence = sequence;
    return true;
  }

  @override
  Future<void> close() {
    _generation++;
    _request++;
    _unreadRequest++;
    _scope = null;
    _loading = false;
    _refreshQueued = false;
    _unreadRefreshing = false;
    _unreadRefreshQueued = false;
    _unreadIssuedSequence = 0;
    _unreadAppliedSequence = 0;
    return super.close();
  }
}
