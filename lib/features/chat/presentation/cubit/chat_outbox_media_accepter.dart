import 'dart:typed_data';

import 'package:shiftly/core/error/failure.dart';
import 'package:shiftly/features/chat/domain/entities/chat_outbox_operation.dart';

import 'chat_message_uuid.dart';
import 'chat_outbox_accepter.dart';
import 'chat_outbox_controller.dart';

Future<String?> acceptChatOutboxMedia(
  ChatOutboxController controller,
  String type,
  Uint8List bytes,
  String mime, {
  int? durationMs,
  String? fileName,
  String? caption,
}) async {
  final host = controller.host;
  final scope = host.cacheScope, generation = host.generation;
  if (scope == null || controller.accepting) return null;
  String? file;
  try {
    file = await host.outbox?.ownMedia(scope, bytes);
    final op = ChatOutboxOperation(
      id: chatMessageUuid(),
      type: type,
      createdAt: DateTime.now().toUtc(),
      file: file,
      mimeType: mime,
      sizeBytes: bytes.length,
      durationMs: durationMs,
      fileName: fileName,
      text: caption,
    );
    if (generation != host.generation ||
        host.cacheScope?.key != scope.key ||
        host.isClosed) {
      if (file != null) await host.outbox!.remove(scope, op);
      return null;
    }
    if (await acceptChatOutboxOperation(controller, op, bytes: bytes)) {
      return op.id;
    }
    if (file != null) await host.outbox!.remove(scope, op);
  } catch (_) {
    if (!host.isClosed) {
      const msg = 'Unable to save media. Keep it and try again.';
      host.emitState(
        host.state.copyWith(
          failure: const Failure(message: msg, kind: FailureKind.server),
        ),
      );
    }
  }
  return null;
}
