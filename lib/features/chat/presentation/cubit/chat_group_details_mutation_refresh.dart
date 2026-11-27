import 'package:shiftly/core/session/feature_scope.dart';
import 'package:shiftly/features/chat/domain/entities/chat_models.dart';

import 'chat_group_details_session.dart';
import 'chat_group_details_state.dart';

mixin ChatGroupDetailsMutationRefresh on ChatGroupDetailsSession {
  Future<bool> refreshAfterMutation(
    FeatureSessionScope scope,
    ChatGroup previous,
    int generation,
  ) async {
    try {
      final updated = await repository.getGroup(scope.workspaceId, previous.id);
      if (!isCurrent(scope, previous.id, generation)) return false;
      if (updated.workspaceId != scope.workspaceId ||
          updated.id != previous.id) {
        throw const FormatException('Invalid chat group response');
      }
      emit(ChatGroupDetailsState(loading: false, group: updated));
      return true;
    } catch (error) {
      if (isCurrent(scope, previous.id, generation)) {
        emit(
          ChatGroupDetailsState(
            loading: false,
            group: previous,
            failure: detailsFailure(
              error,
              'The change was saved, but group details could not be refreshed.',
            ),
          ),
        );
        return true;
      }
      return false;
    }
  }
}
