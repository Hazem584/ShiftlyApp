import 'dart:async';

import 'package:shiftly/features/chat/domain/entities/chat_models.dart';

import 'chat_outbox_controller.dart';
import 'pending_chat_message.dart';

List<PendingChatMessage> withoutCanonicalOutboxPending(
  ChatOutboxController controller,
  List<ChatMessage> messages,
) {
  final host = controller.host, queue = controller.queue;
  final canonicalClientIds = messages
      .where((m) => m.sender.membershipId == host.scope?.membershipId)
      .map((m) => m.clientMessageId)
      .whereType<String>()
      .toSet();
  if (canonicalClientIds.isEmpty) return host.state.pending;
  for (final id in canonicalClientIds) {
    final confirmation = queue.confirmations[id];
    if (confirmation != null && !confirmation.isCompleted) {
      confirmation.complete();
    }
    final operation = queue.operations.remove(id);
    queue.localBytes.remove(id);
    queue.authorizations.remove(id);
    if (operation != null && host.cacheScope != null) {
      unawaited(
        (host.outbox?.remove(host.cacheScope!, operation) ??
                Future<void>.value())
            .catchError((Object _) {}),
      );
    }
  }
  return host.state.pending
      .where((p) => !canonicalClientIds.contains(p.clientMessageId))
      .toList(growable: false);
}
