import 'dart:async';

import 'chat_outbox_controller.dart';

Future<void> restoreChatOutbox(ChatOutboxController controller) async {
  final host = controller.host;
  final key = host.cacheScope, scope = host.scope, group = host.groupId;
  final generation = host.generation;
  if (key == null || host.outbox == null || scope == null || group == null) {
    return;
  }
  final restored = await host.outbox!.restore(key);
  if (!host.scopeCurrent(scope, group, generation)) return;
  for (final operation in restored) {
    if (operation.phase != 'queued') operation.phase = 'failed';
    controller.queue.operations[operation.id] = operation;
    controller.showOperation(operation);
  }
}

Future<void> retryChatOutboxMedia(
  ChatOutboxController controller,
  String id,
) async {
  final host = controller.host;
  final operation = controller.queue.operations[id];
  if (operation == null ||
      operation.phase != 'failed' ||
      host.state.accessLost) {
    return;
  }
  operation.phase = 'queued';
  try {
    await host.outbox?.save(host.cacheScope!, operation);
    controller.showOperation(operation);
    await controller.drain();
  } catch (_) {
    operation.phase = 'failed';
    controller.showOperation(operation);
  }
}

Future<void> drainChatOutboxLane(
  ChatOutboxController controller,
  bool lightweight,
) async {
  if (!controller.runningLanes.add(lightweight)) return;
  final host = controller.host;
  final generation = host.generation;
  try {
    while (!host.isClosed && generation == host.generation) {
      if (host.cacheScope == null ||
          (host.outbox != null &&
              !host.outbox!.storage.writable(host.cacheScope!))) {
        break;
      }
      final operation = controller.queue.operations.values
          .where(
            (p) =>
                p.phase == 'queued' &&
                (p.type == 'TEXT' || p.type == 'LOCATION') == lightweight,
          )
          .firstOrNull;
      if (operation == null) break;
      await controller.delivery.submit(operation, generation);
    }
  } finally {
    controller.runningLanes.remove(lightweight);
    if (!host.isClosed &&
        generation != host.generation &&
        controller.queue.operations.values.any((p) => p.phase == 'queued')) {
      unawaited(controller.drain());
    }
  }
}
