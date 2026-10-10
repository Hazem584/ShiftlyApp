import 'dart:typed_data';

import 'package:shiftly/core/storage/platform_file.dart';
import 'package:shiftly/features/chat/domain/entities/chat_cache_scope.dart';
import 'package:shiftly/features/chat/domain/entities/chat_outbox_operation.dart';
import 'package:shiftly/features/chat/domain/repositories/chat_cache_access.dart';
import 'package:shiftly/features/chat/domain/services/chat_outbox_coordinator.dart';

abstract interface class ChatOutboxStore {
  ChatCacheAccess get storage;
  ChatOutboxCoordinator get coordinator;
  Future<String> ownMedia(ChatCacheScope scope, Uint8List bytes);
  Future<void> save(ChatCacheScope scope, ChatOutboxOperation operation);
  Future<List<ChatOutboxOperation>> restore(ChatCacheScope scope);
  ChatLocalFile mediaFile(String name);
  Future<void> remove(ChatCacheScope scope, ChatOutboxOperation operation);
}
