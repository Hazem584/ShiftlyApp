import 'package:equatable/equatable.dart';
import 'package:shiftly/features/chat/domain/entities/chat_attachment.dart';
import 'package:shiftly/features/chat/domain/entities/chat_location.dart';
import 'package:shiftly/features/chat/domain/entities/chat_message_parser.dart';
import 'package:shiftly/features/chat/domain/entities/chat_reaction.dart';
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
    this.replyPreview,
    this.pinnedAt,
    this.revision = 0,
    this.reactions = const [],
    this.deletedAt,
  });

  final int revision;
  final List<ChatReaction> reactions;
  final DateTime? deletedAt;
  final String id;
  final String groupId;
  final String type;
  final String? text;
  final ChatSender sender;
  final ChatAttachment? attachment;
  final ChatLocation? location;
  final String? clientMessageId;
  final String? replyToMessageId;
  final Map<String, Object?>? replyPreview;
  final DateTime? pinnedAt;
  final DateTime createdAt;

  factory ChatMessage.fromJson(Map<String, Object?> json) =>
      parseChatMessageJson(json);

  @override
  List<Object?> get props => [
    id,
    revision,
    reactions,
    deletedAt,
    groupId,
    type,
    text,
    sender,
    attachment,
    location,
    clientMessageId,
    replyToMessageId,
    replyPreview,
    pinnedAt,
    createdAt,
  ];
}
