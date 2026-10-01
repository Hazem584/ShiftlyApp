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

  FeatureSessionScope? get scope => _scope;

  void bindSession(FeatureSessionScope? scope) {
    final authorized = scope?.isManager == true || scope?.isEmployee == true
        ? scope
        : null;
    if (_scope == authorized) return;
    _scope = authorized;
    _generation++;
    _request++;
    emit(const ChatGroupsState());
    if (authorized != null) unawaited(load());
  }

  Future<void> load({bool refresh = false}) async {
    final scope = _scope;
    if (scope == null) return;
    final generation = _generation;
    final request = ++_request;
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
          unreadCount: results[1] as int,
        ),
      );
    } catch (error) {
      if (!_current(scope, generation, request)) return;
      final failure = _failure(error, 'Unable to load chat groups.');
      emit(
        previous.groups.isNotEmpty
            ? previous.copyWith(refreshing: false, failure: failure)
            : ChatGroupsState(
                loading: false,
                unreadCount: previous.unreadCount,
                failure: failure,
              ),
      );
    }
  }

  Future<void> refreshUnread() async {
    final scope = _scope;
    if (scope == null) return;
    final generation = _generation;
    try {
      final value = await _repository.unreadCount(scope.workspaceId);
      if (_scopeCurrent(scope, generation)) {
        emit(state.copyWith(unreadCount: value));
      }
    } catch (_) {}
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
    Future<ChatGroup> Function(FeatureSessionScope scope) operation,
  ) async {
    final scope = _scope;
    if (scope == null || !scope.isManager) return ChatMutationResult.failure;
    if (state.mutating) return ChatMutationResult.busy;
    final generation = _generation;
    emit(state.copyWith(mutating: true, clearFailure: true));
    try {
      final group = await operation(scope);
      if (!_scopeCurrent(scope, generation)) return ChatMutationResult.stale;
      if (group.workspaceId != scope.workspaceId) {
        throw const FormatException('Cross-workspace chat response');
      }
      final existing = state.groups.any((item) => item.id == group.id);
      emit(
        state.copyWith(
          mutating: false,
          groups: existing
              ? state.groups
                    .map((item) => item.id == group.id ? group : item)
                    .toList()
              : [group, ...state.groups],
        ),
      );
      return ChatMutationResult.success;
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

  Failure _failure(Object error, String fallback) => error is ApiException
      ? error.toFailure()
      : Failure(message: fallback, kind: FailureKind.server);
  bool _current(FeatureSessionScope scope, int generation, int request) =>
      _scopeCurrent(scope, generation) && _request == request;
  bool _scopeCurrent(FeatureSessionScope scope, int generation) =>
      !isClosed && _scope == scope && _generation == generation;
}
