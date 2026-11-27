import 'package:shiftly/core/error/failure.dart';
import 'package:shiftly/features/chat/domain/entities/chat_outbox_operation.dart';

import 'chat_conversation_host.dart';
import 'chat_outbox_queue.dart';
import 'pending_chat_message.dart';

void showChatOutboxOperation(
  ChatConversationHost host,
  ChatOutboxQueue queue,
  ChatOutboxOperation operation, {
  Failure? failure,
}) {
  final type = switch (operation.type) {
    'TEXT' => PendingChatMediaType.text,
    'LOCATION' => PendingChatMediaType.location,
    'IMAGE' => PendingChatMediaType.image,
    'DOCUMENT' => PendingChatMediaType.document,
    _ => PendingChatMediaType.voice,
  };
  final status = switch (operation.phase) {
    'queued' => ChatUploadState.queued,
    'sending' => ChatUploadState.sending,
    'preparing' => ChatUploadState.preparing,
    'uploading' => ChatUploadState.uploading,
    'finalizing' => ChatUploadState.finalizing,
    _ =>
      operation.submitted ? ChatUploadState.uncertain : ChatUploadState.failed,
  };
  final value = PendingChatMessage(
    createdAt: operation.createdAt,
    clientMessageId: operation.id,
    mediaType: type,
    status: status,
    text: operation.text,
    location: operation.location,
    localPath: operation.file == null
        ? null
        : host.outbox?.mediaFile(operation.file!).path,
    previewBytes: type == PendingChatMediaType.image
        ? queue.localBytes[operation.id]
        : null,
    durationMs: operation.durationMs,
    fileName: operation.fileName,
    failure: failure,
    canCancel: !operation.submitted &&
        operation.phase != 'uploading' &&
        operation.phase != 'preparing',
  );
  final pending = [...host.state.pending];
  final index = pending.indexWhere((p) => p.clientMessageId == operation.id);
  if (index < 0) {
    pending.add(value);
  } else {
    pending[index] = value;
  }
  host.emitState(host.state.copyWith(pending: pending, clearFailure: true));
}
