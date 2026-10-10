import 'dart:async';

import 'package:shiftly/core/session/feature_scope.dart';
import 'package:shiftly/features/chat/domain/entities/chat_cache_scope.dart';
import 'package:shiftly/features/chat/domain/entities/chat_models.dart';
import 'package:shiftly/features/chat/domain/repositories/chat_message_store.dart';
import 'package:shiftly/features/chat/domain/repositories/chat_outbox_store.dart';
import 'package:shiftly/features/chat/domain/repositories/chat_repository.dart';

import 'chat_conversation_state.dart';

abstract interface class ChatConversationHost {
  ChatConversationState get state;
  bool get isClosed;
  FeatureSessionScope? get scope;
  String? get groupId;
  int get generation;
  ChatCacheScope? get cacheScope;
  ChatRepository get repository;
  ChatMessageStore? get messageCache;
  ChatOutboxStore? get outbox;
  void Function()? get onChanged;
  void emitState(ChatConversationState value);
  bool scopeCurrent(FeatureSessionScope scope, String groupId, int generation);
  void validateMessages(
    List<ChatMessage> values,
    FeatureSessionScope scope,
    String groupId,
  );
  List<ChatMessage> mergeMessages(
    List<ChatMessage> incoming,
    List<ChatMessage> current,
  );
  void markNewestRead(List<ChatMessage> messages);
  Future<void> load({bool refresh = false});
  Future<void> loseAccess();
}
