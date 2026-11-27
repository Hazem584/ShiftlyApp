import '../entities/chat_group.dart';
import '../entities/chat_inbox_activity.dart';

ChatGroup applyChatInboxActivity(
  ChatGroup group,
  ChatInboxActivity activity,
  String membershipId,
) {
  if (group.id != activity.groupId) return group;
  final latest = group.lastMessage;
  switch (activity) {
    case ChatInboxRead(:final messageId):
      if (latest?.id != messageId || group.unreadCount == 0) return group;
      return _withActivity(group, unreadCount: 0);
    case ChatInboxMessage(:final message):
      if (!activity.isNew && latest?.id != message.id) return group;
      if (latest != null &&
          (message.createdAt.isBefore(latest.createdAt) ||
              (message.id == latest.id &&
                  message.revision <= latest.revision))) {
        return group;
      }
      final hasNewUnread =
          activity.isNew &&
          latest?.id != message.id &&
          message.sender.membershipId != membershipId;
      return _withActivity(
        group,
        message: activity,
        unreadCount: group.unreadCount + (hasNewUnread ? 1 : 0),
      );
  }
}

ChatGroup _withActivity(
  ChatGroup group, {
  ChatInboxMessage? message,
  int? unreadCount,
}) => ChatGroup(
  id: group.id,
  workspaceId: group.workspaceId,
  name: group.name,
  description: group.description,
  memberCount: group.memberCount,
  unreadCount: unreadCount ?? group.unreadCount,
  createdAt: group.createdAt,
  updatedAt: message?.message.createdAt ?? group.updatedAt,
  archivedAt: group.archivedAt,
  archived: group.archived,
  lastMessage: message?.message ?? group.lastMessage,
  members: group.members,
);
