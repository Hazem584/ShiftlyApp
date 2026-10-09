import 'package:shiftly/features/chat/domain/entities/chat_message.dart';

class ChatMessagePage {
  const ChatMessagePage({required this.messages, this.nextCursor});
  final List<ChatMessage> messages;
  final String? nextCursor;
}
