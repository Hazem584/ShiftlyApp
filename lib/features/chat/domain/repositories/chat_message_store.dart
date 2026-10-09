import 'package:shiftly/features/chat/domain/entities/chat_cache_scope.dart';
import 'package:shiftly/features/chat/domain/entities/chat_models.dart';
import 'package:shiftly/features/chat/domain/repositories/chat_cache_access.dart';

abstract interface class ChatMessageStore {
  ChatCacheAccess get storage;
  Future<void> confirm(ChatCacheScope scope, ChatMessage message);
  Future<ChatMessagePage?> read(ChatCacheScope scope, {String? cursor});
  Future<void> write(
    ChatCacheScope scope,
    ChatMessagePage page, {
    String? cursor,
  });
}
