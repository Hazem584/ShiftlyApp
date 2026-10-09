import 'dart:io';

import 'package:shiftly/features/chat/domain/entities/chat_cache_scope.dart';
import 'package:shiftly/features/chat/domain/entities/chat_models.dart';
import 'package:shiftly/features/chat/domain/repositories/chat_cache_access.dart';
import 'package:shiftly/features/chat/domain/repositories/chat_repository.dart';

abstract interface class ChatMediaStore {
  ChatCacheAccess get storage;
  void pin(File file);
  void unpin(File file);
  Future<File> resolve(
    ChatCacheScope scope,
    ChatMessage message,
    ChatRepository repository,
  );
  Future<int> size();
  Future<void> clear();
}
