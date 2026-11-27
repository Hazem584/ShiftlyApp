import 'package:shiftly/core/error/api_exception.dart';
import 'package:shiftly/core/error/failure.dart';
import 'package:shiftly/features/chat/domain/entities/chat_outbox_operation.dart';

import 'chat_message_delivery.dart';

Future<void> handleChatDeliveryError(
  ChatMessageDelivery delivery,
  ChatOutboxOperation operation,
  Object error,
  bool Function() current,
) async {
  if (!current()) return;
  final host = delivery.host, queue = delivery.queue;
  final scope = host.scope!, group = host.groupId!, key = host.cacheScope!;
  if (_isAccessLost(error)) {
    await host.loseAccess();
    return;
  }
  if (error is ApiException &&
      const [
        'CHAT_MEDIA_OBJECT_INVALID',
        'CHAT_MEDIA_OBJECT_MISSING',
        'CHAT_UPLOAD_EXPIRED',
      ].contains(error.code)) {
    operation.submitted = false;
    try {
      if (operation.uploadId != null) {
        await host.repository.cancelUpload(
          scope.workspaceId,
          group,
          operation.uploadId!,
        );
      }
    } catch (_) {}
    operation.uploadId = null;
    queue.authorizations.remove(operation.id);
  }
  operation.phase = 'failed';
  try {
    await host.outbox?.save(key, operation);
  } catch (_) {}
  if (current()) {
    delivery.showOperation(
      operation,
      failure: _failure(
        error,
        operation.submitted
            ? 'Confirmation unavailable. Retry safely with the same message ID.'
            : 'Unable to send media.',
      ),
    );
  }
}

Failure _failure(Object error, String fallback) => error is ApiException
    ? error.toFailure()
    : Failure(message: fallback, kind: FailureKind.server);

bool _isAccessLost(Object error) =>
    error is ApiException &&
    (error.statusCode == 403 ||
        (error.statusCode == 404 && error.code == 'CHAT_GROUP_NOT_FOUND'));
