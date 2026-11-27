import 'chat_message.dart';

sealed class ChatInboxActivity {
  const ChatInboxActivity(this.groupId);
  final String groupId;
}

final class ChatInboxMessage extends ChatInboxActivity {
  ChatInboxMessage(this.message, {this.isNew = true}) : super(message.groupId);

  final ChatMessage message;
  final bool isNew;
}

final class ChatInboxRead extends ChatInboxActivity {
  const ChatInboxRead(super.groupId, this.messageId);
  final String messageId;
}
