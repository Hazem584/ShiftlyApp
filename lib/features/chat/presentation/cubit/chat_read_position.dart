import 'package:shiftly/features/chat/domain/entities/chat_models.dart';

class ChatReadPosition implements Comparable<ChatReadPosition> {
  const ChatReadPosition(this.createdAt, this.messageId);

  factory ChatReadPosition.fromMessage(ChatMessage message) =>
      ChatReadPosition(message.createdAt.toUtc(), message.id);

  final DateTime createdAt;
  final String messageId;

  @override
  int compareTo(ChatReadPosition other) {
    final byTime = createdAt.compareTo(other.createdAt);
    return byTime == 0 ? messageId.compareTo(other.messageId) : byTime;
  }

  @override
  bool operator ==(Object other) =>
      other is ChatReadPosition &&
      createdAt == other.createdAt &&
      messageId == other.messageId;

  @override
  int get hashCode => Object.hash(createdAt, messageId);
}
