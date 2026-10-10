import 'dart:typed_data';

abstract final class ChatMediaValidation {
  static const imageMaxBytes = 5 * 1024 * 1024;
  static const voiceMaxBytes = 10 * 1024 * 1024;
  static const voiceMaxDurationMs = 10 * 60 * 1000;

  static String? voiceMime(Uint8List bytes) {
    if (bytes.length >= 12 && _ascii(bytes, 4, 'ftyp')) return 'audio/mp4';
    if (bytes.length >= 4 && _matches(bytes, const [0x1a, 0x45, 0xdf, 0xa3])) {
      return 'audio/webm';
    }
    if (bytes.length >= 4 && _ascii(bytes, 0, 'OggS')) return 'audio/ogg';
    return null;
  }

  static String? imageMime(Uint8List bytes) {
    if (bytes.isEmpty || bytes.length > imageMaxBytes) return null;
    if (bytes.length >= 4 &&
        bytes[0] == 0xff &&
        bytes[1] == 0xd8 &&
        bytes[2] == 0xff &&
        bytes[bytes.length - 2] == 0xff &&
        bytes[bytes.length - 1] == 0xd9) {
      return 'image/jpeg';
    }
    if (bytes.length >= 45 &&
        _matches(bytes, const [
          0x89,
          0x50,
          0x4e,
          0x47,
          0x0d,
          0x0a,
          0x1a,
          0x0a,
        ]) &&
        _ascii(bytes, 12, 'IHDR') &&
        _matchesAt(bytes, bytes.length - 12, const [
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
        _ascii(bytes, 0, 'RIFF') &&
        _littleEndianUint32(bytes, 4) + 8 == bytes.length &&
        _ascii(bytes, 8, 'WEBP') &&
        const [
          'VP8 ',
          'VP8L',
          'VP8X',
        ].any((value) => _ascii(bytes, 12, value))) {
      return 'image/webp';
    }
    return null;
  }

  static bool validVoice({
    required Uint8List bytes,
    required String mimeType,
    required int durationMs,
  }) {
    if (bytes.isEmpty ||
        bytes.length > voiceMaxBytes ||
        durationMs < 1 ||
        durationMs > voiceMaxDurationMs) {
      return false;
    }
    return switch (mimeType) {
      'audio/mp4' => bytes.length >= 12 && _ascii(bytes, 4, 'ftyp'),
      'audio/aac' =>
        bytes.length >= 2 && bytes[0] == 0xff && (bytes[1] & 0xf6) == 0xf0,
      'audio/mpeg' =>
        bytes.length >= 3 &&
            (_ascii(bytes, 0, 'ID3') ||
                (bytes[0] == 0xff && (bytes[1] & 0xe0) == 0xe0)),
      'audio/ogg' => bytes.length >= 4 && _ascii(bytes, 0, 'OggS'),
      'audio/webm' =>
        bytes.length >= 4 && _matches(bytes, const [0x1a, 0x45, 0xdf, 0xa3]),
      _ => false,
    };
  }

  static bool _matches(Uint8List bytes, List<int> signature) {
    return _matchesAt(bytes, 0, signature);
  }

  static bool _matchesAt(Uint8List bytes, int offset, List<int> signature) {
    if (offset < 0 || bytes.length < offset + signature.length) return false;
    for (var index = 0; index < signature.length; index++) {
      if (bytes[offset + index] != signature[index]) return false;
    }
    return true;
  }

  static int _littleEndianUint32(Uint8List bytes, int offset) =>
      bytes[offset] |
      (bytes[offset + 1] << 8) |
      (bytes[offset + 2] << 16) |
      (bytes[offset + 3] << 24);

  static bool _ascii(Uint8List bytes, int offset, String value) {
    if (bytes.length < offset + value.length) return false;
    for (var index = 0; index < value.length; index++) {
      if (bytes[offset + index] != value.codeUnitAt(index)) return false;
    }
    return true;
  }
}
