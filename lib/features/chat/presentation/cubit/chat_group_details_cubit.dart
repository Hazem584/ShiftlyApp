import 'package:shiftly/features/chat/domain/entities/chat_models.dart';

import 'chat_group_details_loader.dart';
import 'chat_group_details_mutation_refresh.dart';
import 'chat_group_details_session.dart';
import 'chat_group_details_state.dart';

export 'chat_group_details_state.dart';

class ChatGroupDetailsCubit extends ChatGroupDetailsSession
    with ChatGroupDetailsLoader, ChatGroupDetailsMutationRefresh {
  ChatGroupDetailsCubit(
    super.repository, {
    super.onChanged,
    super.loadGroup,
    super.cacheDatabase,
    super.realtime,
  });

  Future<bool> addMembers(List<String> ids) {
    if (ids.isEmpty) return Future.value(false);
    return _mutateMembers(
      (workspaceId, group) => repository.addMembers(workspaceId, group.id, ids),
      'Unable to add members.',
    );
  }

  Future<bool> removeMember(String membershipId) => _mutateMembers(
    (workspaceId, group) =>
        repository.removeMember(workspaceId, group.id, membershipId),
    'Unable to remove the member.',
  );

  Future<bool> _mutateMembers(
    Future<Object?> Function(String workspaceId, ChatGroup group) apply,
    String fallback,
  ) async {
    final scope = this.scope;
    final group = state.group;
    if (scope == null ||
        group == null ||
        !scope.isManager ||
        group.isArchived ||
        state.mutating) {
      return false;
    }

    final generation = this.generation;
    emit(ChatGroupDetailsState(loading: false, group: group, mutating: true));
    try {
      await apply(scope.workspaceId, group);
      if (!isCurrent(scope, group.id, generation)) return false;
      onChanged?.call();
      return await refreshAfterMutation(scope, group, generation);
    } catch (error) {
      if (!isCurrent(scope, group.id, generation)) return false;
      emit(
        ChatGroupDetailsState(
          loading: false,
          group: group,
          failure: detailsFailure(error, fallback),
        ),
      );
      return false;
    }
  }
}
