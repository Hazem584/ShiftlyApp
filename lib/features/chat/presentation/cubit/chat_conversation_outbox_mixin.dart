import 'dart:async';
import 'dart:typed_data';

import 'package:shiftly/features/chat/domain/entities/chat_models.dart';
import 'package:shiftly/features/chat/domain/repositories/chat_realtime.dart';

import 'chat_conversation_host_mixin.dart';
import 'chat_conversation_state.dart';

mixin ChatConversationOutboxMixin on ChatConversationHostMixin {
  ChatRealtimeSubscription? realtimeSubscription;
  Timer? refreshDebounce;

  Future<void> loadOlder() => pager.loadOlder();
  void syncInboxGroup(ChatGroup? group) => live.syncInboxGroup(group);
  void applyMessageUpdate(ChatMessage message) {
    if (!isClosed && !state.accessLost && message.groupId == activeGroupId) {
      live.accept(message);
    }
  }

  Future<bool> send(String value, {String? replyToMessageId}) =>
      outgoing.send(value, replyToMessageId: replyToMessageId);
  Future<bool> retrySend() => outgoing.retrySend();
  Future<String?> sendDocument(Uint8List bytes, String fileName) =>
      outgoing.sendDocument(bytes, fileName);
  Future<String?> sendImage(Uint8List bytes, {String? caption}) =>
      outgoing.sendImage(bytes, caption: caption);
  Future<String?> sendVoice({
    required Uint8List bytes,
    required String mimeType,
    required int durationMs,
  }) => outgoing.sendVoice(
    bytes: bytes,
    mimeType: mimeType,
    durationMs: durationMs,
  );
  Future<bool> sendLocation(ChatLocation location) =>
      outgoing.sendLocation(location);
  Future<void> retryMedia(String id) => outgoing.retryMedia(id);
  Future<void> cancelPending(String id) => outgoing.cancelPending(id);

  void onRealtimeInsert(int gen) {
    if (gen != activeGeneration) return;
    refreshDebounce?.cancel();
    refreshDebounce = Timer(const Duration(milliseconds: 300), () {
      if (!isClosed && gen == activeGeneration) unawaited(load(refresh: true));
    });
  }

  void cancelRealtime() {
    refreshDebounce?.cancel();
    refreshDebounce = null;
    final sub = realtimeSubscription;
    realtimeSubscription = null;
    if (sub != null) unawaited(sub.cancel());
  }

  void onAccessChanged() {
    final key = cacheScope;
    if (key == null || outbox!.storage.authorized(key)) return;
    outgoing.clear();
    cancelRealtime();
    activeGeneration++;
    pager.reset();
    if (!isClosed) {
      emit(const ChatConversationState(loading: false, accessLost: true));
    }
  }
}
