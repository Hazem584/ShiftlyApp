import 'dart:async';
import 'dart:typed_data';

import 'package:shiftly/core/error/failure.dart';
import 'package:shiftly/features/chat/domain/entities/chat_models.dart';
import 'package:shiftly/features/chat/domain/entities/chat_outbox_operation.dart';

import 'chat_conversation_host.dart';
import 'chat_message_delivery.dart';
import 'chat_outbox_canceller.dart';
import 'chat_outbox_drainer.dart';
import 'chat_outbox_presenter.dart';
import 'chat_outbox_queue.dart';
import 'chat_outbox_reconciler.dart';
import 'chat_outbox_senders.dart';
import 'pending_chat_message.dart';

class ChatOutboxController {
  ChatOutboxController(this.host);
  final ChatConversationHost host;
  final queue = ChatOutboxQueue();
  late final delivery = ChatMessageDelivery(host, queue, showOperation);
  final Set<bool> runningLanes = {};
  bool accepting = false;

  void showOperation(ChatOutboxOperation operation, {Failure? failure}) =>
      showChatOutboxOperation(host, queue, operation, failure: failure);

  Future<bool> send(String value, {String? replyToMessageId}) =>
      sendOutboxText(this, value, replyToMessageId: replyToMessageId);

  Future<bool> retrySend() async {
    final op = queue.operations.values
        .where((p) => p.type == 'TEXT' && p.phase == 'failed')
        .firstOrNull;
    if (op == null) return false;
    await retryMedia(op.id);
    return true;
  }

  Future<String?> sendImage(Uint8List bytes, {String? caption}) =>
      sendOutboxImage(this, bytes, caption: caption);

  Future<String?> sendVoice({
    required Uint8List bytes,
    required String mimeType,
    required int durationMs,
  }) => sendOutboxVoice(
    this,
    bytes: bytes,
    mimeType: mimeType,
    durationMs: durationMs,
  );

  Future<String?> sendDocument(Uint8List bytes, String fileName) =>
      sendOutboxDocument(this, bytes, fileName);

  Future<bool> sendLocation(ChatLocation location) =>
      sendOutboxLocation(this, location);

  Future<void> restore() => restoreChatOutbox(this);
  Future<void> retryMedia(String id) => retryChatOutboxMedia(this, id);
  Future<void> drain() => Future.wait([
    drainChatOutboxLane(this, true),
    drainChatOutboxLane(this, false),
  ]);
  Future<void> cancelPending(String id) => cancelChatOutboxPending(this, id);
  List<PendingChatMessage> withoutCanonicalPending(List<ChatMessage> msgs) =>
      withoutCanonicalOutboxPending(this, msgs);

  void clear() {
    queue.uploadCancellation?.cancel();
    for (final c in queue.confirmations.values) {
      if (!c.isCompleted) c.complete();
    }
    queue.confirmations.clear();
    queue.operations.clear();
    queue.localBytes.clear();
    queue.authorizations.clear();
  }
}
