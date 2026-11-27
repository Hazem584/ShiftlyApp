import 'package:shiftly/features/chat/domain/entities/chat_models.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart' as stream;

import 'stream_message_identity.dart';
import 'stream_message_mapper.dart';

ChatGroup mapStreamGroup(
  ChatGroup base,
  stream.Channel channel, {
  int? streamUnreadCount,
}) {
  final messages =
      channel.state?.messages
          .where(
            (message) =>
                !message.state.isSending &&
                !message.state.isSendingFailed &&
                isSupportedStreamMessage(message),
          )
          .toList() ??
      [];
  messages.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  final reads = channel.state?.read ?? [];
  var latest = base.lastMessage;
  if (messages.isNotEmpty &&
      (latest == null ||
          !messages.first.createdAt.isBefore(latest.createdAt))) {
    latest = mapStreamMessage(messages.first, base.id);
  }
  return ChatGroup(
    id: base.id,
    workspaceId: base.workspaceId,
    name: base.name,
    description: base.description,
    createdAt: base.createdAt,
    updatedAt: latest?.createdAt ?? base.updatedAt,
    archivedAt: base.archivedAt,
    archived: base.archived,
    memberCount: base.memberCount,
    unreadCount:
        base.unreadCount +
        (streamUnreadCount ?? channel.state?.unreadCount ?? 0),
    lastMessage: latest,
    members: [
      for (final member in base.members)
        ChatMember(
          membershipId: member.membershipId,
          profileId: member.profileId,
          fullName: member.fullName,
          email: member.email,
          avatarUrl: member.avatarUrl,
          role: member.role,
          joinedAt: member.joinedAt,
          lastReadMessageId:
              reads
                  .where((r) => r.user.id == member.membershipId)
                  .firstOrNull
                  ?.lastReadMessageId ??
              member.lastReadMessageId,
          lastReadMessageCreatedAt:
              reads
                  .where((r) => r.user.id == member.membershipId)
                  .firstOrNull
                  ?.lastRead ??
              member.lastReadMessageCreatedAt,
        ),
    ],
  );
}
