import 'dart:typed_data';

import 'chat_byte_signatures.dart';
import 'chat_media_limits.dart';

String? detectChatVoiceMime(Uint8List bytes) {
  if (bytes.length >= 12 && matchesAscii(bytes, 4, 'ftyp')) return 'audio/mp4';
  if (bytes.length >= 4 &&
      matchesBytes(bytes, const [0x1a, 0x45, 0xdf, 0xa3])) {
    return 'audio/webm';
  }
  if (bytes.length >= 4 && matchesAscii(bytes, 0, 'OggS')) return 'audio/ogg';
  return null;
}

bool validChatVoice({
  required Uint8List bytes,
  required String mimeType,
  required int durationMs,
}) {
  if (bytes.isEmpty ||
      bytes.length > ChatMediaLimits.voiceMaxBytes ||
      durationMs < 1 ||
      durationMs > ChatMediaLimits.voiceMaxDurationMs) {
    return false;
  }
  return switch (mimeType) {
    'audio/mp4' => bytes.length >= 12 && matchesAscii(bytes, 4, 'ftyp'),
    'audio/aac' =>
      bytes.length >= 2 && bytes[0] == 0xff && (bytes[1] & 0xf6) == 0xf0,
    'audio/mpeg' =>
      bytes.length >= 3 &&
          (matchesAscii(bytes, 0, 'ID3') ||
              (bytes[0] == 0xff && (bytes[1] & 0xe0) == 0xe0)),
    'audio/ogg' => bytes.length >= 4 && matchesAscii(bytes, 0, 'OggS'),
    'audio/webm' =>
      bytes.length >= 4 && matchesBytes(bytes, const [0x1a, 0x45, 0xdf, 0xa3]),
    _ => false,
  };
}
