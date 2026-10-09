import 'package:equatable/equatable.dart';
import 'package:shiftly/features/chat/domain/entities/chat_attachment.dart';
import 'package:shiftly/features/chat/domain/entities/chat_location.dart';
import 'package:shiftly/features/chat/domain/entities/chat_models_parsers.dart';
import 'package:shiftly/features/chat/domain/entities/chat_sender.dart';

class ChatMessage extends Equatable {
  const ChatMessage({
    required this.id,
    required this.groupId,
    required this.type,
    this.text,
    required this.sender,
    required this.createdAt,
    this.attachment,
    this.location,
    this.clientMessageId,
    this.replyToMessageId,
  });

  final String id;
  final String groupId;
  final String type;
  final String? text;
  final ChatSender sender;
  final ChatAttachment? attachment;
  final ChatLocation? location;
  final String? clientMessageId;
  final String? replyToMessageId;
  final DateTime createdAt;

  factory ChatMessage.fromJson(Map<String, Object?> json) {
    final type = chatModelsText(json, 'type');
    final rawText = json['text'];
    if (rawText != null && rawText is! String) {
      throw const FormatException('Invalid message text');
    }
    final body = rawText as String?;
    if (type == 'TEXT' && (body == null || body.trim().isEmpty)) {
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
      createdAt: chatModelsDate(json, 'createdAt'),
    );
  }

  @override
  List<Object?> get props => [
    id,
    groupId,
    type,
    text,
    sender,
    attachment,
    location,
    clientMessageId,
    replyToMessageId,
    createdAt,
  ];
}
