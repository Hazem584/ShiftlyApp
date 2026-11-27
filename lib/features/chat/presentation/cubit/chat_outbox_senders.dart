import 'dart:typed_data';

import 'package:shiftly/features/chat/domain/services/chat_document_validation.dart';
import 'package:shiftly/features/chat/domain/services/chat_media_validation.dart';

import 'chat_outbox_controller.dart';
import 'chat_outbox_media_accepter.dart';

export 'chat_outbox_lightweight_senders.dart';

Future<String?> sendOutboxImage(
  ChatOutboxController c,
  Uint8List bytes, {
  String? caption,
}) async {
  if ((caption?.trim().length ?? 0) > 1000) return null;
  final owned = Uint8List.fromList(bytes);
  final mime = ChatMediaValidation.imageMime(owned);
  if (mime == null) return null;
  return acceptChatOutboxMedia(
    c,
    'IMAGE',
    owned,
    mime,
    caption: caption?.trim().isEmpty == true ? null : caption?.trim(),
  );
}

Future<String?> sendOutboxVoice(
  ChatOutboxController c, {
  required Uint8List bytes,
  required String mimeType,
  required int durationMs,
}) async {
  final owned = Uint8List.fromList(bytes);
  if (!ChatMediaValidation.validVoice(
    bytes: owned,
    mimeType: mimeType,
    durationMs: durationMs,
  )) {
    return null;
  }
  return acceptChatOutboxMedia(
    c,
    'VOICE',
    owned,
    mimeType,
    durationMs: durationMs,
  );
}

Future<String?> sendOutboxDocument(
  ChatOutboxController c,
  Uint8List bytes,
  String fileName,
) => !ChatDocumentValidation.valid(bytes, fileName)
    ? Future.value(null)
    : acceptChatOutboxMedia(
        c,
        'DOCUMENT',
        Uint8List.fromList(bytes),
        ChatDocumentValidation.mimeForName(fileName)!,
        fileName: fileName,
      );
