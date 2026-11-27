import 'package:shiftly/core/error/api_exception.dart';
import 'package:shiftly/features/chat/domain/entities/chat_cache_scope.dart';

import 'chat_group_details_session.dart';
import 'chat_group_details_state.dart';

mixin ChatGroupDetailsLoader on ChatGroupDetailsSession {
  @override
  Future<void> load() async {
    final scope = this.scope;
    final groupId = this.groupId;
    if (scope == null || groupId == null || loadingDetails) return;
    loadingDetails = true;
    final previous = state;
    final generation = this.generation;
    final cacheRevision = cacheDatabase?.revision;
    try {
      final group =
          await (loadGroup?.call() ??
              repository.getGroup(scope.workspaceId, groupId));
      if (!isCurrent(scope, groupId, generation)) return;
      if (cacheRevision != cacheDatabase?.revision) return;
      if (group.workspaceId != scope.workspaceId || group.id != groupId) {
        throw const FormatException('Invalid chat group response');
      }
      emit(ChatGroupDetailsState(loading: false, group: group));
      cacheDatabase?.grant(
        ChatCacheScope.fromSession(scope, groupId),
        archived: group.isArchived,
      );
    } catch (error) {
      if (!isCurrent(scope, groupId, generation)) return;
      if (error is ApiException &&
          (error.statusCode == 403 ||
              (error.statusCode == 404 &&
                  error.code == 'CHAT_GROUP_NOT_FOUND'))) {
        await cacheDatabase?.revoke(ChatCacheScope.fromSession(scope, groupId));
        if (!isCurrent(scope, groupId, generation)) return;
        emit(
          ChatGroupDetailsState(
            loading: false,
            failure: detailsFailure(error, 'Chat access unavailable.'),
          ),
        );
        return;
      }
      emit(
        ChatGroupDetailsState(
          loading: false,
          group: previous.group,
          failure: detailsFailure(error, 'Unable to load group details.'),
        ),
      );
    } finally {
      if (isCurrent(scope, groupId, generation)) loadingDetails = false;
    }
  }
}
