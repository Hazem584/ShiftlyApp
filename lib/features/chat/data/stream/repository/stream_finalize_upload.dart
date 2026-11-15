import 'package:shiftly/features/chat/domain/entities/chat_models.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart' as stream;

import '../stream_chat_repository_base.dart';
import '../stream_chat_request.dart';

mixin StreamFinalizeUpload on StreamChatRepositoryBase {
  @override
  Future<ChatMessage> finalizeUpload(
    String workspaceId,
    String groupId, {
    required String type,
    required String uploadId,
    required String clientMessageId,
    String? caption,
  }) => streamChatRequest(() async {
    if (!await streamEnabled(workspaceId)) {
      return legacy.finalizeUpload(
        workspaceId,
        groupId,
        type: type,
        uploadId: uploadId,
        clientMessageId: clientMessageId,
        caption: caption,
      );
    }
    final result = await sendStreamMessage(
      workspaceId,
      groupId,
      stream.Message(
        id: clientMessageId,
        text: caption,
        attachments: [media.attachment(uploadId, workspaceId, groupId)],
      ),
    );
    media.complete(uploadId);
    return result;
  });
}
