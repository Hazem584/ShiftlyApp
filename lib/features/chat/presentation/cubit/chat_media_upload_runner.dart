import 'package:shiftly/features/chat/domain/entities/chat_outbox_operation.dart';
import 'package:shiftly/features/chat/domain/repositories/chat_repository.dart';

import 'chat_media_upload_auth.dart';
import 'chat_message_delivery.dart';

Future<void> prepareAndUploadChatMedia(
  ChatMessageDelivery delivery,
  ChatOutboxOperation operation,
  bool Function() current,
  Future<void> Function(String, {bool submitted}) phase,
) async {
  final host = delivery.host, queue = delivery.queue;
  final scope = host.scope!, group = host.groupId!;
  await phase('preparing');
  final auth = await ensureChatUploadAuthorization(delivery, operation, current);
  if (auth == null) return;
  await phase('uploading');
  final bytes = queue.localBytes[operation.id] ??
      await host.outbox!.mediaFile(operation.file!).readAsBytes();
  if (!current()) return;
  queue.uploadCancellation = ChatUploadCancellation();
  try {
    await host.repository.uploadSigned(
      auth,
      bytes,
      operation.mimeType!,
      cancellation: queue.uploadCancellation,
      onProgress: (sent, total) {
        if (!current() || total <= 0) return;
        if (host.state.pending.any((p) => p.clientMessageId == operation.id)) {
          host.emitState(
            host.state.copyWith(
              pending: host.state.pending
                  .map(
                    (p) => p.clientMessageId == operation.id
                        ? p.copyWith(progress: sent / total)
                        : p,
                  )
                  .toList(),
            ),
          );
        }
      },
    );
  } catch (_) {
    if (current()) {
      try {
        await host.repository.cancelUpload(scope.workspaceId, group, auth.uploadId);
      } catch (_) {}
      operation.uploadId = null;
      queue.authorizations.remove(operation.id);
    }
    rethrow;
  }
}
