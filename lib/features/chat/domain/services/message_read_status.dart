import 'package:shiftly/features/chat/domain/entities/chat_models.dart';

/// Receipts refer to current recipients who belonged to the group at send time.
/// Missing membership or read-position data must never imply everyone read it.
bool messageReadByAll(ChatMessage message, ChatGroup? group) {
  if (group == null ||
      group.id != message.groupId ||
      group.members.length != group.memberCount) {
    return false;
  }
  final recipients = group.members.where(
    (member) =>
        member.membershipId != message.sender.membershipId &&
        (member.joinedAt == null ||
            !member.joinedAt!.isAfter(message.createdAt)),
  );
  if (recipients.isEmpty) return false;
  return recipients.every((member) {
    final readAt = member.lastReadMessageCreatedAt;
    final readId = member.lastReadMessageId;
    if (readAt == null || readId == null) return false;
    final time = readAt.compareTo(message.createdAt);
    return time > 0 || (time == 0 && readId.compareTo(message.id) >= 0);
  });
}
