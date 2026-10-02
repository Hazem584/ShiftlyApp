import 'package:equatable/equatable.dart';

final RegExp _uuid = RegExp(
  r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-4[0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
);

String chatUuid(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is! String || !_uuid.hasMatch(value)) {
    throw FormatException('Invalid $key');
  }
  return value;
}

String? chatOptionalUuid(Object? value) {
  if (value == null) return null;
  if (value is! String || !_uuid.hasMatch(value)) {
    throw const FormatException('Invalid UUID');
  }
  return value;
}

Map<String, Object?> chatMap(Object? value, [String label = 'object']) {
  if (value is! Map) throw FormatException('Invalid $label');
  return Map<String, Object?>.from(value);
}

List<Object?> chatList(Object? value, [String label = 'list']) {
  if (value is! List) throw FormatException('Invalid $label');
  return value;
}

String _text(Map<String, Object?> json, String key, {bool empty = false}) {
  final value = json[key];
  if (value is! String || (!empty && value.trim().isEmpty)) {
    throw FormatException('Invalid $key');
  }
  return value;
}

String? _optionalText(Object? value) =>
    value is String && value.trim().isNotEmpty ? value : null;

int _count(Object? value, String label) {
  if (value is! int || value < 0) throw FormatException('Invalid $label');
  return value;
}

DateTime _date(Map<String, Object?> json, String key) {
  final value = json[key];
  final date = value is String ? DateTime.tryParse(value) : null;
  if (date == null) throw FormatException('Invalid $key');
  return date.toUtc();
}

DateTime? _optionalDate(Object? value) {
  if (value == null) return null;
  final date = value is String ? DateTime.tryParse(value) : null;
  if (date == null) throw const FormatException('Invalid timestamp');
  return date.toUtc();
}

class ChatSender extends Equatable {
  const ChatSender({
    required this.membershipId,
    this.profileId,
    this.fullName,
    this.avatarUrl,
  });

  final String membershipId;
  final String? profileId;
  final String? fullName;
  final String? avatarUrl;

  String get displayName => fullName ?? 'Workspace member';

  factory ChatSender.fromJson(Map<String, Object?> json) {
    final profile = json['profile'] is Map
        ? chatMap(json['profile'], 'sender.profile')
        : const <String, Object?>{};
    return ChatSender(
      membershipId:
          chatOptionalUuid(json['membershipId'] ?? json['id']) ??
          (throw const FormatException('Invalid membershipId')),
      profileId: chatOptionalUuid(json['profileId'] ?? profile['id']),
      fullName: _optionalText(json['fullName'] ?? profile['fullName']),
      avatarUrl: _optionalText(json['avatarUrl'] ?? profile['avatarUrl']),
    );
  }

  @override
  List<Object?> get props => [membershipId, profileId, fullName, avatarUrl];
}

class ChatMessage extends Equatable {
  const ChatMessage({
    required this.id,
    required this.groupId,
    required this.type,
    required this.text,
    required this.sender,
    required this.createdAt,
    this.clientMessageId,
    this.replyToMessageId,
  });

  final String id;
  final String groupId;
  final String type;
  final String text;
  final ChatSender sender;
  final String? clientMessageId;
  final String? replyToMessageId;
  final DateTime createdAt;

  factory ChatMessage.fromJson(Map<String, Object?> json) {
    final type = _text(json, 'type');
    if (type != 'TEXT') throw const FormatException('Unsupported message type');
    final body = _text(json, 'text');
    if (body.length > 4000) throw const FormatException('Invalid message text');
    final senderValue = json['sender'] ?? json['senderMembership'];
    return ChatMessage(
      id: chatUuid(json, 'id'),
      groupId: chatUuid(json, 'groupId'),
      type: type,
      text: body,
      sender: ChatSender.fromJson(chatMap(senderValue, 'sender')),
      clientMessageId: chatOptionalUuid(json['clientMessageId']),
      replyToMessageId: chatOptionalUuid(json['replyToMessageId']),
      createdAt: _date(json, 'createdAt'),
    );
  }

  @override
  List<Object?> get props => [
    id,
    groupId,
    type,
    text,
    sender,
    clientMessageId,
    replyToMessageId,
    createdAt,
  ];
}

class ChatMember extends Equatable {
  const ChatMember({
    required this.membershipId,
    this.profileId,
    this.fullName,
    this.email,
    this.avatarUrl,
    this.role,
  });

  final String membershipId;
  final String? profileId;
  final String? fullName;
  final String? email;
  final String? avatarUrl;
  final String? role;

  String get displayName => fullName ?? email ?? 'Workspace member';

  factory ChatMember.fromJson(Map<String, Object?> json) {
    final membership = json['membership'] is Map
        ? chatMap(json['membership'], 'membership')
        : json;
    final profile = membership['profile'] is Map
        ? chatMap(membership['profile'], 'member.profile')
        : const <String, Object?>{};
    return ChatMember(
      membershipId:
          chatOptionalUuid(membership['membershipId'] ?? membership['id']) ??
          (throw const FormatException('Invalid membershipId')),
      profileId: chatOptionalUuid(membership['profileId'] ?? profile['id']),
      fullName: _optionalText(membership['fullName'] ?? profile['fullName']),
      email: _optionalText(membership['email'] ?? profile['email']),
      avatarUrl: _optionalText(membership['avatarUrl'] ?? profile['avatarUrl']),
      role: _optionalText(membership['role']),
    );
  }

  @override
  List<Object?> get props => [
    membershipId,
    profileId,
    fullName,
    email,
    avatarUrl,
    role,
  ];
}

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

class ChatMessagePage {
  const ChatMessagePage({required this.messages, this.nextCursor});
  final List<ChatMessage> messages;
  final String? nextCursor;
}
