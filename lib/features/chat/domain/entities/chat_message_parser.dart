import 'package:shiftly/features/chat/domain/entities/chat_attachment.dart';
import 'package:shiftly/features/chat/domain/entities/chat_location.dart';
import 'package:shiftly/features/chat/domain/entities/chat_message.dart';
import 'package:shiftly/features/chat/domain/entities/chat_models_parsers.dart';
import 'package:shiftly/features/chat/domain/entities/chat_reaction.dart';
import 'package:shiftly/features/chat/domain/entities/chat_sender.dart';

ChatMessage parseChatMessageJson(Map<String, Object?> json) {
  final type = chatModelsText(json, 'type');
  final rawText = json['text'];
  if (rawText != null && rawText is! String) {
    throw const FormatException('Invalid message text');
  }
  final body = rawText as String?;
  if (type == 'TEXT' &&
      json['deletedAt'] == null &&
      (body == null || body.trim().isEmpty)) {
    throw const FormatException('Invalid message text');
  }
  if (body != null && body.length > 4000) {
    throw const FormatException('Invalid message text');
  }
  final senderValue = json['sender'] ?? json['senderMembership'];
  final rawAttachment = json['attachment'];
  final rawLocation = json['location'];
  return ChatMessage(
    id: chatUuid(json, 'id'),
    groupId: chatUuid(json, 'groupId'),
    type: type,
    revision: json['revision'] is int ? json['revision'] as int : 0,
    deletedAt: json['deletedAt'] == null
        ? null
        : DateTime.parse(json['deletedAt'] as String),
    reactions: (json['reactions'] as List? ?? [])
        .map((r) => ChatReaction.fromJson(chatMap(r)))
        .toList(),
    text: body,
    sender: ChatSender.fromJson(chatMap(senderValue, 'sender')),
    attachment: rawAttachment == null
        ? null
        : ChatAttachment.fromJson(chatMap(rawAttachment, 'attachment')),
    location: rawLocation == null
        ? null
        : ChatLocation.fromJson(chatMap(rawLocation, 'location')),
    clientMessageId: chatOptionalUuid(json['clientMessageId']),
    replyToMessageId: chatOptionalUuid(json['replyToMessageId']),
    replyPreview: json['replyToMessage'] == null
        ? null
        : chatMap(json['replyToMessage'], 'reply preview'),
    pinnedAt: json['pinnedAt'] == null
        ? null
        : DateTime.parse(json['pinnedAt'] as String),
    createdAt: chatModelsDate(json, 'createdAt'),
  );
}
