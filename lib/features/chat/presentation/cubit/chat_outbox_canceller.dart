import 'package:shiftly/features/chat/presentation/cubit/chat_outbox_controller.dart';

Future<void> cancelChatOutboxPending(
  ChatOutboxController controller,
  String id,
) async {
  final host = controller.host, queue = controller.queue;
  final operation = queue.operations[id], key = host.cacheScope;
  if (operation == null ||
      key == null ||
      operation.submitted ||
      !const ['queued', 'failed'].contains(operation.phase)) {
    return;
  }
  operation.phase = 'cancelled';
  if (operation.uploadId != null) {
    try {
      await host.repository.cancelUpload(
        key.workspaceId,
        key.groupId,
        operation.uploadId!,
      );
    } catch (_) {
      operation.phase = 'failed';
      controller.showOperation(operation);
      return;
    }
  }
  await host.outbox?.remove(key, operation);
  queue.operations.remove(id);
  queue.localBytes.remove(id);
  queue.authorizations.remove(id);
  if (!host.isClosed && host.cacheScope?.key == key.key) {
    host.emitState(
      host.state.copyWith(
        pending:
            host.state.pending.where((p) => p.clientMessageId != id).toList(),
      ),
    );
  }
}
