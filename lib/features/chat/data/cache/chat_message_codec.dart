import 'package:shiftly/features/chat/domain/entities/chat_models.dart';

abstract final class ChatMessageCodec {
  static Map<String, Object?> encode(ChatMessage message) => {
    'id': message.id, 'groupId': message.groupId, 'type': message.type,
    'text': message.text,
    'createdAt': message.createdAt.toUtc().toIso8601String(),
    'clientMessageId': message.clientMessageId,
    'replyToMessageId': message.replyToMessageId,
    'sender': {
      'membershipId': message.sender.membershipId,
      'profileId': message.sender.profileId,
      'fullName': message.sender.fullName,
    },
    // Avatar/signed URLs are not durable private-message identity.
    if (message.attachment case final attachment?)
      'attachment': {
        'id': attachment.id,
        'category': attachment.category,
        'mimeType': attachment.mimeType,
        'sizeBytes': attachment.sizeBytes,
        'durationMs': attachment.durationMs,
      },
    if (message.location case final location?) 'location': location.toJson(),
  };
  static List<ChatMessage> decode(Object? rows) {
    if (rows is! List) return [];
    final values = <ChatMessage>[];
    for (final row in rows) {
      try {
        values.add(ChatMessage.fromJson(chatMap(row)));
      } on FormatException {
        /* Skip corrupt/unsupported records without breaking history. */
      }
    }
    return values;
  }
}
