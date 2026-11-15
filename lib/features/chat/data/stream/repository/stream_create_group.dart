import 'package:shiftly/features/chat/domain/entities/chat_models.dart';

import '../stream_chat_repository_base.dart';

mixin StreamCreateGroup on StreamChatRepositoryBase {
  @override
  Future<ChatGroup> createGroup(
    String workspaceId, {
    required String name,
    String? description,
    required List<String> memberMembershipIds,
  }) => legacy.createGroup(
    workspaceId,
    name: name,
    description: description,
    memberMembershipIds: memberMembershipIds,
  );
}
