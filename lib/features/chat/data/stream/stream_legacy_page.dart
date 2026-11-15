import 'package:shiftly/features/chat/domain/entities/chat_models.dart';

ChatMessagePage legacyStreamPage(ChatMessagePage page) => ChatMessagePage(
  messages: page.messages,
  nextCursor: page.nextCursor == null ? null : 'legacy:${page.nextCursor}',
);
