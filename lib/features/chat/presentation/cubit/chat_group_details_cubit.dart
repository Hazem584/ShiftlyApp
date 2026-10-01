import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/error/api_exception.dart';
import 'package:shiftly/core/error/failure.dart';
import 'package:shiftly/core/session/feature_scope.dart';
import 'package:shiftly/features/chat/data/chat_models.dart';
import 'package:shiftly/features/chat/data/chat_repository.dart';

class ChatGroupDetailsState extends Equatable {
  const ChatGroupDetailsState({
    this.loading = true,
    this.group,
    this.mutating = false,
    this.failure,
  });
  final bool loading;
  final ChatGroup? group;
  final bool mutating;
  final Failure? failure;

  @override
  List<Object?> get props => [loading, group, mutating, failure];
}

class ChatGroupDetailsCubit extends Cubit<ChatGroupDetailsState> {
  ChatGroupDetailsCubit(this._repository)
    : super(const ChatGroupDetailsState());
  final ChatRepository _repository;
  FeatureSessionScope? _scope;
  String? _groupId;
  var _generation = 0;

  void bind(FeatureSessionScope scope, String groupId) {
    if (_scope == scope && _groupId == groupId) return;
    _scope = scope;
    _groupId = groupId;
    _generation++;
    emit(const ChatGroupDetailsState());
    load();
  }

  Future<void> load() async {
    final scope = _scope;
    final groupId = _groupId;
    if (scope == null || groupId == null) return;
    final generation = _generation;
    try {
      final group = await _repository.getGroup(scope.workspaceId, groupId);
      if (!_current(scope, groupId, generation)) return;
      if (group.workspaceId != scope.workspaceId || group.id != groupId) {
        throw const FormatException('Invalid chat group response');
      }
      emit(ChatGroupDetailsState(loading: false, group: group));
    } catch (error) {
      if (!_current(scope, groupId, generation)) return;
      emit(
        ChatGroupDetailsState(
          loading: false,
          failure: _failure(error, 'Unable to load group details.'),
        ),
      );
    }
  }

  Future<bool> addMembers(List<String> ids) async {
    final scope = _scope;
    final group = state.group;
    if (scope == null ||
        group == null ||
        !scope.isManager ||
        group.isArchived ||
        state.mutating ||
        ids.isEmpty) {
      return false;
    }
    final generation = _generation;
    emit(ChatGroupDetailsState(loading: false, group: group, mutating: true));
    try {
      final updated = await _repository.addMembers(
        scope.workspaceId,
        group.id,
        ids,
      );
      if (!_current(scope, group.id, generation)) return false;
      emit(ChatGroupDetailsState(loading: false, group: updated));
      return true;
    } catch (error) {
      if (!_current(scope, group.id, generation)) return false;
      emit(
        ChatGroupDetailsState(
          loading: false,
          group: group,
          failure: _failure(error, 'Unable to add members.'),
        ),
      );
      return false;
    }
  }

  Future<bool> removeMember(String membershipId) async {
    final scope = _scope;
    final group = state.group;
    if (scope == null ||
        group == null ||
        !scope.isManager ||
        group.isArchived ||
        state.mutating) {
      return false;
    }
    final generation = _generation;
    emit(ChatGroupDetailsState(loading: false, group: group, mutating: true));
    try {
      await _repository.removeMember(scope.workspaceId, group.id, membershipId);
      if (!_current(scope, group.id, generation)) return false;
      await load();
      return _current(scope, group.id, generation);
    } catch (error) {
      if (!_current(scope, group.id, generation)) return false;
      emit(
        ChatGroupDetailsState(
          loading: false,
          group: group,
          failure: _failure(error, 'Unable to remove the member.'),
        ),
      );
      return false;
    }
  }

  Failure _failure(Object error, String fallback) =>
      error is ApiException ? error.toFailure() : Failure(message: fallback);
  bool _current(FeatureSessionScope scope, String groupId, int generation) =>
      !isClosed &&
      _scope == scope &&
      _groupId == groupId &&
      _generation == generation;
}
