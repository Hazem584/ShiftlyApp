import 'package:shiftly/features/chat/domain/entities/chat_models.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart' as stream;

import 'stream_message_attachment.dart';
import 'stream_message_reactions.dart';
import 'stream_message_reply_preview.dart';

ChatMessage mapStreamMessage(stream.Message source, String groupId) {
  final data = source.extraData, file = source.attachments.firstOrNull;
  final location = data['shiftly_location'];
  final type = location is Map
      ? 'LOCATION'
      : file == null
      ? 'TEXT'
      : file.type == 'image'
      ? 'IMAGE'
      : file.type == 'audio'
      ? 'VOICE'
      : 'DOCUMENT';
  return ChatMessage(
    id: source.id,
    groupId: groupId,
    type: type,
    text: source.text,
    clientMessageId: source.id,
    sender: ChatSender(
      membershipId: source.user!.id,
      fullName: source.user!.name,
      avatarUrl: source.user!.image,
    ),
    createdAt: source.createdAt.toUtc(),
    deletedAt: source.deletedAt,
    revision: (source.updatedAt).millisecondsSinceEpoch,
    attachment: mapStreamAttachment(file, type),
    location: location is Map
        ? ChatLocation.fromJson(Map<String, Object?>.from(location))
        : null,
    reactions: mapStreamReactions(source),
    replyToMessageId:
        source.quotedMessageId ?? data['shiftly_reply_id'] as String?,
    replyPreview: mapStreamReplyPreview(source),
    pinnedAt: source.pinnedAt,
  );
}
