part of '../../chat_conversation_cubit.dart';

class _ReadPosition implements Comparable<_ReadPosition> {
  const _ReadPosition(this.createdAt, this.messageId);

  factory _ReadPosition.fromMessage(ChatMessage message) =>
      _ReadPosition(message.createdAt.toUtc(), message.id);

  final DateTime createdAt;
  final String messageId;

  @override
  int compareTo(_ReadPosition other) {
    final byTime = createdAt.compareTo(other.createdAt);
    return byTime == 0 ? messageId.compareTo(other.messageId) : byTime;
  }

  @override
  bool operator ==(Object other) =>
      other is _ReadPosition &&
      createdAt == other.createdAt &&
      messageId == other.messageId;

  @override
  int get hashCode => Object.hash(createdAt, messageId);
}
