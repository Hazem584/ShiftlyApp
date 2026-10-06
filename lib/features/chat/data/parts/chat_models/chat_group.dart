part of '../../chat_models.dart';

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

  factory ChatGroup.fromJson(Map<String, Object?> json) {
    final rawMembers = json['members'];
    final members = rawMembers == null
        ? const <ChatMember>[]
        : chatList(rawMembers, 'members')
              .map((e) => ChatMember.fromJson(chatMap(e, 'member')))
              .toList(growable: false);
    final last = json['lastMessage'];
    final archivedValue = json['isArchived'] ?? json['archived'];
    if (archivedValue != null && archivedValue is! bool) {
      throw const FormatException('Invalid archived state');
    }
    final countValue = json['memberCount'];
    final rawCount = json['_count'];
    final countMap = rawCount == null ? null : chatMap(rawCount, '_count');
    final memberCount = countValue != null
        ? _count(countValue, 'memberCount')
        : countMap?['members'] != null
        ? _count(countMap!['members'], '_count.members')
        : members.length;
    final description = json['description'];
    if (description != null && description is! String) {
      throw const FormatException('Invalid description');
    }
    if (description is String && description.length > 500) {
      throw const FormatException('Invalid description');
    }
    final name = _text(json, 'name');
    if (name.length > 80) throw const FormatException('Invalid name');
    return ChatGroup(
      id: chatUuid(json, 'id'),
      workspaceId: chatUuid(json, 'workspaceId'),
      name: name,
      description: _optionalText(description),
      memberCount: memberCount,
      unreadCount: json['unreadCount'] == null
          ? 0
          : _count(json['unreadCount'], 'unreadCount'),
      archivedAt: _optionalDate(json['archivedAt']),
      archived: archivedValue == true,
      lastMessage: last == null
          ? null
          : ChatMessage.fromJson(chatMap(last, 'lastMessage')),
      members: members,
      createdAt: _date(json, 'createdAt'),
      updatedAt: _date(json, 'updatedAt'),
    );
  }

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
