import 'package:shiftly/features/chat/domain/entities/chat_models.dart';
import 'package:shiftly/features/chat/domain/entities/chat_outbox_operation.dart';

import 'chat_media_upload_runner.dart';
import 'chat_message_delivery.dart';
import 'chat_message_delivery_commit.dart';

Future<ChatMessage?> sendChatLightweightOperation(
  ChatMessageDelivery delivery,
  ChatOutboxOperation op,
  bool Function() current,
  Future<void> Function(String, {bool submitted}) phase,
  Future<ChatMessage?> Function(Future<ChatMessage>) ack,
) async {
  await phase('sending', submitted: true);
  final host = delivery.host;
  final w = host.scope!.workspaceId, g = host.groupId!;
  return ack(
    op.type == 'TEXT'
        ? retryChatIdempotent(
            () => host.repository.sendMessage(
              w,
              g,
              text: op.text!,
              replyToMessageId: op.replyToMessageId,
              clientMessageId: op.id,
            ),
            current,
          )
        : retryChatIdempotent(
            () => host.repository.sendLocation(
              w,
              g,
              location: op.location!,
              clientMessageId: op.id,
            ),
            current,
          ),
  );
}

Future<ChatMessage?> sendChatMediaOperation(
  ChatMessageDelivery delivery,
  ChatOutboxOperation op,
  bool Function() current,
  Future<void> Function(String, {bool submitted}) phase,
  Future<ChatMessage?> Function(Future<ChatMessage>) ack,
) async {
  if (!op.submitted) {
    await prepareAndUploadChatMedia(delivery, op, current, phase);
  }
  await phase('finalizing', submitted: true);
  final host = delivery.host;
  return ack(
    retryChatIdempotent(
      () => host.repository.finalizeUpload(
        host.scope!.workspaceId,
        host.groupId!,
        type: op.type,
        uploadId: op.uploadId!,
        clientMessageId: op.id,
        caption: op.text,
      ),
      current,
    ),
  );
}
