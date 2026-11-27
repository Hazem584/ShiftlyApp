import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/session/feature_scope.dart';
import 'package:shiftly/features/chat/domain/entities/chat_models.dart';
import 'package:shiftly/features/chat/domain/repositories/chat_message_store.dart';
import 'package:shiftly/features/chat/domain/repositories/chat_outbox_store.dart';
import 'package:shiftly/features/chat/domain/repositories/chat_realtime.dart';
import 'package:shiftly/features/chat/domain/repositories/chat_repository.dart';

import 'chat_conversation_host_mixin.dart';
import 'chat_conversation_outbox_mixin.dart';
import 'chat_conversation_state.dart';

export 'chat_conversation_state.dart';
export 'pending_chat_message.dart';

class ChatConversationCubit extends Cubit<ChatConversationState>
    with ChatConversationHostMixin, ChatConversationOutboxMixin {
  ChatConversationCubit(
    this._repository,
    this._realtime, {
    this.onChanged,
    this.loadGroup,
    this.messageCache,
    this.outbox,
  }) : super(const ChatConversationState()) {
    outbox?.storage.listeners.add(onAccessChanged);
  }
  @override
  final ChatMessageStore? messageCache;
  @override
  final ChatOutboxStore? outbox;
  final ChatRepository _repository;
  final ChatRealtime _realtime;
  @override
  final void Function()? onChanged;
  @override
  final Future<ChatGroup> Function()? loadGroup;

  @override
  ChatRepository get repository => _repository;

  void bind(FeatureSessionScope? scope, String groupId) {
    FeatureSessionScope? valid;
    try {
      valid = scope != null && chatOptionalUuid(groupId) != null ? scope : null;
    } on FormatException {
      valid = null;
    }
    if (sessionScope == valid && activeGroupId == groupId) return;
    outgoing.clear();
    cancelRealtime();
    sessionScope = valid;
    activeGroupId = valid == null ? null : groupId;
    activeGeneration++;
    pager.reset();
    reads.clear();
    emit(const ChatConversationState());
    if (valid != null) {
      final gen = activeGeneration;
      realtimeSubscription = _realtime is ChatLiveRealtime
          ? live.bind(_realtime, groupId)
          : _realtime.subscribeToGroup(groupId, () => onRealtimeInsert(gen));
      unawaited(load());
    }
  }

  @override
  Future<void> loseAccess() async {
    final key = cacheScope;
    outgoing.clear();
    cancelRealtime();
    if (!isClosed) {
      emit(const ChatConversationState(loading: false, accessLost: true));
    }
    if (key != null) await outbox?.storage.revoke(key);
  }

  @override
  Future<void> close() async {
    outbox?.storage.listeners.remove(onAccessChanged);
    outgoing.clear();
    activeGeneration++;
    pager.reset();
    sessionScope = null;
    activeGroupId = null;
    reads.clear();
    refreshDebounce?.cancel();
    refreshDebounce = null;
    final sub = realtimeSubscription;
    realtimeSubscription = null;
    await sub?.cancel();
    await pager.pagePersistence;
    return super.close();
  }
}
