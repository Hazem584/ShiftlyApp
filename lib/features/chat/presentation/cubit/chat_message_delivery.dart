import 'dart:async';

import 'package:shiftly/core/error/failure.dart';
import 'package:shiftly/features/chat/domain/entities/chat_models.dart';
import 'package:shiftly/features/chat/domain/entities/chat_outbox_operation.dart';

import 'chat_conversation_host.dart';
import 'chat_message_delivery_commit.dart';
import 'chat_message_delivery_error.dart';
import 'chat_message_delivery_senders.dart';
import 'chat_outbox_queue.dart';

class ChatMessageDelivery {
  ChatMessageDelivery(this.host, this.queue, this.showOperation);
  final ChatConversationHost host;
  final ChatOutboxQueue queue;
  final void Function(ChatOutboxOperation, {Failure? failure}) showOperation;

  Future<void> submit(ChatOutboxOperation operation, int generation) async {
    final scope = host.scope, group = host.groupId, key = host.cacheScope;
    if (scope == null || group == null || key == null) return;
    bool current() =>
        host.scopeCurrent(scope, group, generation) &&
        queue.operations[operation.id] == operation &&
        (host.outbox == null || host.outbox!.storage.writable(key));
    Future<void> phase(String value, {bool submitted = false}) async {
      if (!current()) throw StateError('Chat access unavailable');
      operation.phase = value;
      operation.submitted = operation.submitted || submitted;
      await host.outbox?.save(key, operation);
      if (!current()) throw StateError('Chat access unavailable');
      showOperation(operation);
    }

    final lightweight =
        operation.type == 'TEXT' || operation.type == 'LOCATION';
    await host.outbox?.coordinator.acquire(lightweight: lightweight);
    final confirmation = Completer<void>();
    queue.confirmations[operation.id] = confirmation;
    Future<ChatMessage?> ack(Future<ChatMessage> res) =>
        Future.any<ChatMessage?>([res, confirmation.future.then((_) => null)]);
    try {
      if (!current()) return;
      final canonical = lightweight
          ? await sendChatLightweightOperation(this, operation, current, phase, ack)
          : await sendChatMediaOperation(this, operation, current, phase, ack);
      if (canonical == null || !current()) return;
      await commitDeliveredChatMessage(
        this,
        operation,
        canonical,
        generation,
        lightweight,
      );
    } catch (error) {
      await handleChatDeliveryError(this, operation, error, current);
    } finally {
      if (identical(queue.confirmations[operation.id], confirmation)) {
        queue.confirmations.remove(operation.id);
      }
      if (!lightweight) queue.uploadCancellation = null;
      host.outbox?.coordinator.release(lightweight: lightweight);
    }
  }
}
