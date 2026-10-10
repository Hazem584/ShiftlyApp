import 'package:flutter_test/flutter_test.dart';
import 'package:shiftly/features/chat/domain/entities/chat_models.dart';
import 'package:shiftly/features/chat/domain/services/message_read_status.dart';

void main() {
  final sentAt = DateTime.utc(2026, 10, 10, 10);
  final message = ChatMessage(
    id: '00000002',
    groupId: 'group',
    type: 'TEXT',
    text: 'Hello',
    sender: const ChatSender(membershipId: 'sender'),
    createdAt: sentAt,
  );
  ChatMember recipient(
    String id, {
    DateTime? readAt,
    String? readId,
    DateTime? joinedAt,
  }) => ChatMember(
    membershipId: id,
    joinedAt: joinedAt,
    lastReadMessageId: readId,
    lastReadMessageCreatedAt: readAt,
  );
  ChatGroup group(List<ChatMember> members, {int? count}) => ChatGroup(
    id: 'group',
    workspaceId: 'workspace',
    name: 'Team',
    memberCount: count ?? members.length,
    unreadCount: 0,
    createdAt: sentAt,
    updatedAt: sentAt,
    members: members,
  );

  test('requires every recipient; an absent receipt never implies read', () {
    final read = recipient('one', readAt: sentAt, readId: message.id);
    expect(messageReadByAll(message, group([read, recipient('two')])), isFalse);
    expect(messageReadByAll(message, group([read])), isTrue);
    expect(messageReadByAll(message, group([read], count: 2)), isFalse);
    expect(messageReadByAll(message, null), isFalse);
    expect(messageReadByAll(message, group([])), isFalse);
  });

  test(
    'ignores sender and later joiners, orders ties by canonical message ID',
    () {
      final read = recipient('one', readAt: sentAt, readId: '00000003');
      expect(
        messageReadByAll(
          message,
          group([
            recipient('sender'),
            read,
            recipient('new', joinedAt: sentAt.add(const Duration(minutes: 1))),
          ]),
        ),
        isTrue,
      );
      expect(
        messageReadByAll(
          message,
          group([recipient('one', readAt: sentAt, readId: '00000001')]),
        ),
        isFalse,
      );
      expect(
        messageReadByAll(
          message,
          group([
            recipient(
              'one',
              readAt: sentAt.subtract(const Duration(seconds: 1)),
              readId: '00000003',
            ),
          ]),
        ),
        isFalse,
      );
    },
  );
}
