import 'package:shiftly/features/chat/domain/entities/chat_models.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart' as stream;

abstract final class StreamChatMapper {
  static final _uuid = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-4[0-9a-fA-F]{3}-[89aAbB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
  );
  static bool supported(stream.Message message) =>
      _uuid.hasMatch(message.id) && _uuid.hasMatch(message.user?.id ?? '');
  static ChatMessage message(stream.Message source, String groupId) {
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
    final quoted = source.quotedMessage;
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
      attachment: file == null
          ? null
          : ChatAttachment(
              id:
                  (file.extraData['shiftly_attachment_id'] as String?) ??
                  file.id,
              category: type,
              mimeType: file.mimeType ?? 'application/octet-stream',
              sizeBytes: file.fileSize ?? 1,
              fileName: file.title,
              durationMs: file.extraData['shiftly_duration_ms'] as int?,
            ),
      location: location is Map
          ? ChatLocation.fromJson(Map<String, Object?>.from(location))
          : null,
      reactions: [
        for (final reaction in source.latestReactions ?? <stream.Reaction>[])
          if (ChatReaction.choices.contains(reaction.type) &&
              _uuid.hasMatch(reaction.userId ?? reaction.user?.id ?? ''))
            ChatReaction(
              emoji: reaction.type,
              membershipId: reaction.userId ?? reaction.user!.id,
            ),
      ],
      replyToMessageId:
          source.quotedMessageId ?? data['shiftly_reply_id'] as String?,
      replyPreview: quoted == null
          ? (data['shiftly_reply'] as Map?)?.cast<String, Object?>()
          : {
              'id': quoted.id,
              'text': quoted.text,
              'type': 'TEXT',
              'sender': {
                'membershipId': quoted.user?.id,
                'fullName': quoted.user?.name,
              },
            },
      pinnedAt: source.pinnedAt,
    );
  }

  static ChatGroup group(ChatGroup base, stream.Channel channel) {
    final messages = channel.state?.messages.where(supported).toList() ?? [];
    messages.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final reads = channel.state?.read ?? [];
    return ChatGroup(
      id: base.id,
      workspaceId: base.workspaceId,
      name: base.name,
      description: base.description,
      createdAt: base.createdAt,
      updatedAt: messages.isEmpty ? base.updatedAt : messages.first.createdAt,
      archivedAt: base.archivedAt,
      archived: base.archived,
      memberCount: base.memberCount,
      unreadCount: base.unreadCount + channel.state!.unreadCount,
      lastMessage: messages.isEmpty
          ? base.lastMessage
          : message(messages.first, base.id),
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
}
