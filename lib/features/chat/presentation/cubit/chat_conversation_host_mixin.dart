import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/session/feature_scope.dart';
import 'package:shiftly/features/chat/domain/entities/chat_cache_scope.dart';
import 'package:shiftly/features/chat/domain/entities/chat_models.dart';

import 'chat_conversation_host.dart';
import 'chat_conversation_pager.dart';
import 'chat_conversation_state.dart';
import 'chat_live_sync.dart';
import 'chat_message_merger.dart';
import 'chat_outbox_controller.dart';
import 'chat_read_receipts.dart';
import 'pending_chat_message.dart';

mixin ChatConversationHostMixin on Cubit<ChatConversationState>
    implements ChatConversationHost {
  FeatureSessionScope? sessionScope;
  String? activeGroupId;
  var activeGeneration = 0;
  Future<ChatGroup> Function()? get loadGroup;

  late final live = ChatLiveSync(this);
  late final reads = ChatReadReceipts(this);
  late final outgoing = ChatOutboxController(this);
  late final pager = ChatConversationPager(
    this,
    loadGroup: loadGroup,
    restoreOutbox: () => outgoing.restore(),
    drainOutbox: () => outgoing.drain(),
    clearInboxHint: live.clearInboxHint,
  );

  @override
  FeatureSessionScope? get scope => sessionScope;
  @override
  String? get groupId => activeGroupId;
  @override
  int get generation => activeGeneration;
  @override
  ChatCacheScope? get cacheScope =>
      sessionScope == null || activeGroupId == null
          ? null
          : ChatCacheScope.fromSession(sessionScope!, activeGroupId!);
  @override
  void emitState(ChatConversationState value) => emit(value);
  @override
  bool scopeCurrent(FeatureSessionScope s, String g, int gen) =>
      !isClosed &&
      sessionScope == s &&
      activeGroupId == g &&
      activeGeneration == gen;
  @override
  void validateMessages(
    List<ChatMessage> values,
    FeatureSessionScope scope,
    String groupId,
  ) => validateChatMessages(values, scope, groupId);
  @override
  List<ChatMessage> mergeMessages(
    List<ChatMessage> incoming,
    List<ChatMessage> current,
  ) => mergeChatMessages(incoming, current);
  @override
  List<PendingChatMessage> confirmPending(List<ChatMessage> messages) =>
      outgoing.withoutCanonicalPending(messages);
  @override
  void markNewestRead(List<ChatMessage> messages) =>
      reads.markNewestRead(messages);
  @override
  Future<void> load({bool refresh = false}) => pager.load(refresh: refresh);
}
