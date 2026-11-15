import 'dart:typed_data';

import 'chat_byte_signatures.dart';
import 'chat_media_limits.dart';

String? detectChatImageMime(Uint8List bytes) {
  if (bytes.isEmpty || bytes.length > ChatMediaLimits.imageMaxBytes) {
    return null;
  }
  if (bytes.length >= 4 &&
      bytes[0] == 0xff &&
      bytes[1] == 0xd8 &&
      bytes[2] == 0xff &&
      bytes[bytes.length - 2] == 0xff &&
      bytes[bytes.length - 1] == 0xd9) {
    return 'image/jpeg';
  }
  if (bytes.length >= 45 &&
      matchesBytes(bytes, const [
        0x89,
        0x50,
        0x4e,
        0x47,
        0x0d,
        0x0a,
        0x1a,
        0x0a,
      ]) &&
      matchesAscii(bytes, 12, 'IHDR') &&
      matchesBytesAt(bytes, bytes.length - 12, const [
        0,
        0,
        0,
        0,
        0x49,
        0x45,
        0x4e,
        0x44,
        0xae,
        0x42,
        0x60,
        0x82,
      ])) {
    return 'image/png';
  }
  if (bytes.length >= 20 &&
      matchesAscii(bytes, 0, 'RIFF') &&
      littleEndianUint32(bytes, 4) + 8 == bytes.length &&
      matchesAscii(bytes, 8, 'WEBP') &&
      const [
        'VP8 ',
        'VP8L',
        'VP8X',
      ].any((value) => matchesAscii(bytes, 12, value))) {
    return 'image/webp';
  }
  return null;
}
