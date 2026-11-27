import 'package:shiftly/features/chat/domain/entities/chat_models.dart';
import 'package:shiftly/features/chat/domain/entities/chat_outbox_operation.dart';

import 'chat_message_delivery.dart';

Future<ChatUploadAuthorization?> ensureChatUploadAuthorization(
  ChatMessageDelivery delivery,
  ChatOutboxOperation operation,
  bool Function() current,
) async {
  final host = delivery.host, queue = delivery.queue;
  final scope = host.scope!, group = host.groupId!, key = host.cacheScope!;
  if (operation.uploadId != null &&
      !queue.authorizations.containsKey(operation.id)) {
    await host.repository.cancelUpload(
      scope.workspaceId,
      group,
      operation.uploadId!,
    );
    operation.uploadId = null;
  }
  var auth = queue.authorizations[operation.id];
  if (auth == null || !auth.expiresAt.isAfter(DateTime.now().toUtc())) {
    if (auth != null) {
      await host.repository.cancelUpload(
        scope.workspaceId,
        group,
        auth.uploadId,
      );
    }
    auth = await host.repository.initiateUpload(
      scope.workspaceId,
      group,
      type: operation.type,
      mimeType: operation.mimeType!,
      sizeBytes: operation.sizeBytes!,
      durationMs: operation.durationMs,
      fileName: operation.fileName,
    );
    if (!current()) return null;
    operation.uploadId = auth.uploadId;
    queue.authorizations[operation.id] = auth;
    await host.outbox?.save(key, operation);
  }
  return auth;
}
