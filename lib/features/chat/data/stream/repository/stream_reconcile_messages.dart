import 'package:shiftly/features/chat/domain/entities/chat_models.dart';

import '../stream_chat_mapper.dart';
import '../stream_chat_repository_base.dart';
import '../stream_chat_request.dart';

mixin StreamReconcileMessages on StreamChatRepositoryBase {
  @override
  Future<List<ChatMessage>> reconcileMessages(
    String workspaceId,
    String groupId,
    List<String> ids,
  ) => streamChatRequest(() async {
    if (!await streamEnabled(workspaceId)) {
      return legacy.reconcileMessages(workspaceId, groupId, ids);
    }
    final channel = await connection.channel(workspaceId, groupId);
    final response = await channel.getMessagesById(ids);
    final current = response.messages
        .where(StreamChatMapper.supported)
        .map((m) => StreamChatMapper.message(m, groupId))
        .toList();
    final missing = ids.where((id) => !current.any((m) => m.id == id)).toList();
    return [
      ...current,
      if (missing.isNotEmpty)
        ...await legacy.reconcileMessages(workspaceId, groupId, missing),
    ];
  });
}
