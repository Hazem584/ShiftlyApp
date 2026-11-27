import 'package:equatable/equatable.dart';
import 'package:shiftly/features/chat/domain/entities/chat_group_parser.dart';
import 'package:shiftly/features/chat/domain/entities/chat_member.dart';
import 'package:shiftly/features/chat/domain/entities/chat_message.dart';

class ChatGroup extends Equatable {
  const ChatGroup({
    required this.id,
    required this.workspaceId,
    required this.name,
    required this.memberCount,
    required this.unreadCount,
    required this.createdAt,
    required this.updatedAt,
    this.description,
    this.archivedAt,
    this.archived = false,
    this.lastMessage,
    this.members = const [],
  });

  final String id;
  final String workspaceId;
  final String name;
  final String? description;
  final int memberCount;
  final int unreadCount;
  final DateTime? archivedAt;
  final bool archived;
  final ChatMessage? lastMessage;
  final List<ChatMember> members;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isArchived => archived || archivedAt != null;

  factory ChatGroup.fromJson(Map<String, Object?> json) =>
      parseChatGroupJson(json);

  @override
  List<Object?> get props => [
    id,
    workspaceId,
    name,
    description,
    memberCount,
    unreadCount,
    archivedAt,
    archived,
    lastMessage,
    members,
    createdAt,
    updatedAt,
  ];
}
