import 'dart:async';
import 'dart:typed_data';

import 'package:shiftly/core/error/failure.dart';
import 'package:shiftly/features/chat/domain/entities/chat_outbox_operation.dart';

import 'chat_outbox_controller.dart';

Future<bool> acceptChatOutboxOperation(
  ChatOutboxController controller,
  ChatOutboxOperation operation, {
  Uint8List? bytes,
}) async {
  final host = controller.host;
  final scope = host.scope, group = host.groupId, key = host.cacheScope;
  if (scope == null ||
      group == null ||
      key == null ||
      host.state.accessLost ||
      controller.accepting ||
      (host.outbox != null && !host.outbox!.storage.writable(key))) {
    return false;
  }
  final generation = host.generation;
  controller.accepting = true;
  try {
    await host.outbox?.save(key, operation);
    if (!host.scopeCurrent(scope, group, generation)) {
      await host.outbox?.remove(key, operation);
      return false;
    }
    controller.queue.operations[operation.id] = operation;
    if (bytes != null) controller.queue.localBytes[operation.id] = bytes;
    controller.showOperation(operation);
    unawaited(controller.drain());
    return true;
  } catch (_) {
    if (host.scopeCurrent(scope, group, generation)) {
      const msg = 'Unable to save this message. Keep your input and retry.';
      host.emitState(
        host.state.copyWith(
          failure: const Failure(message: msg, kind: FailureKind.server),
        ),
      );
    }
    return false;
  } finally {
    controller.accepting = false;
  }
}
