import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:shiftly/features/chat/domain/services/chat_document_validation.dart';
import 'package:shiftly/features/chat/domain/services/chat_media_validation.dart';

class ChatMediaInspection {
  const ChatMediaInspection({
    required this.bytes,
    required this.type,
    required this.mimeType,
    required this.sizeBytes,
    this.fileName = '',
    this.durationMs = 0,
  });
  final Uint8List bytes;
  final String type, mimeType, fileName;
  final int sizeBytes, durationMs;
}

/// Avoid isolate startup/copy overhead for small attachments. This is a
/// conservative cutoff, not a device-specific performance guarantee.
Future<String?> inspectChatMedia(ChatMediaInspection input) =>
    input.bytes.length >= 256 * 1024
    ? compute(chatMediaDigest, input, debugLabel: 'shiftly.chat.media')
    : Future.value(chatMediaDigest(input));

/// Validates and hashes the same byte snapshot, read exactly once by the caller.
String? chatMediaDigest(ChatMediaInspection input) {
  final bytes = input.bytes;
  if (bytes.length != input.sizeBytes || bytes.isEmpty) return null;
  final valid = switch (input.type) {
    'DOCUMENT' =>
      ChatDocumentValidation.valid(bytes, input.fileName) &&
          ChatDocumentValidation.mimeForName(input.fileName) == input.mimeType,
    'IMAGE' => ChatMediaValidation.imageMime(bytes) == input.mimeType,
    'VOICE' => ChatMediaValidation.validVoice(
      bytes: bytes,
      mimeType: input.mimeType,
      durationMs: input.durationMs,
    ),
    _ => false,
  };
  return valid ? sha256.convert(bytes).toString() : null;
}
