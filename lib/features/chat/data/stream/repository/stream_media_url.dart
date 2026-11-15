import 'package:shiftly/features/chat/domain/entities/chat_models.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart' as stream;

import '../stream_attachment_url.dart';
import '../stream_chat_repository_base.dart';
import '../stream_chat_request.dart';

mixin StreamMediaUrl on StreamChatRepositoryBase {
  @override
  Future<ChatMediaUrl> mediaUrl(
    String workspaceId,
    String groupId,
    String messageId,
  ) => streamChatRequest(() async {
    if (!await streamEnabled(workspaceId)) {
      return legacy.mediaUrl(workspaceId, groupId, messageId);
    }
    // A single-message lookup refreshes Stream's expiring CDN signatures.
    // Do not reuse the channel's cached attachment URL when the user retries.
    final client = (await connection.clientFor(workspaceId))!;
    stream.GetMessageResponse response;
    try {
      response = await client.getMessage(messageId);
    } on stream.StreamChatNetworkError catch (error) {
      if (error.statusCode != 404) rethrow;
      return legacy.mediaUrl(workspaceId, groupId, messageId);
    }
    return streamAttachmentUrl(response, groupId);
  });
}
