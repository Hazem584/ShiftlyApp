import 'package:shiftly/core/storage/platform_file.dart';
import 'package:shiftly/features/chat/domain/entities/chat_cache_scope.dart';
import 'package:shiftly/features/chat/domain/entities/chat_models.dart';
import 'package:shiftly/features/chat/domain/repositories/chat_cache_access.dart';
import 'package:shiftly/features/chat/domain/repositories/chat_repository.dart';

abstract interface class ChatMediaStore {
  ChatCacheAccess get storage;
  void pin(ChatLocalFile file);
  void unpin(ChatLocalFile file);
  Future<ChatLocalFile> resolve(
    ChatCacheScope scope,
    ChatMessage message,
    ChatRepository repository,
  );
  Future<int> size();
  Future<void> clear();
}
