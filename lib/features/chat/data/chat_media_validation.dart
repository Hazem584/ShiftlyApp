import 'dart:typed_data';

abstract final class ChatMediaValidation {
  static const imageMaxBytes = 5 * 1024 * 1024;
  static const voiceMaxBytes = 10 * 1024 * 1024;
  static const voiceMaxDurationMs = 10 * 60 * 1000;

  static String? imageMime(Uint8List bytes) {
    if (bytes.length >= 3 &&
        bytes[0] == 0xff &&
        bytes[1] == 0xd8 &&
        bytes[2] == 0xff) {
      return 'image/jpeg';
    }
    if (bytes.length >= 8 &&
        _matches(bytes, const [
          0x89,
          0x50,
          0x4e,
          0x47,
          0x0d,
          0x0a,
          0x1a,
          0x0a,
        ])) {
      return 'image/png';
    }
    if (bytes.length >= 12 &&
        _ascii(bytes, 0, 'RIFF') &&
        _ascii(bytes, 8, 'WEBP')) {
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
    for (var index = 0; index < signature.length; index++) {
      if (bytes[index] != signature[index]) return false;
    }
    return true;
  }

  static bool _ascii(Uint8List bytes, int offset, String value) {
    if (bytes.length < offset + value.length) return false;
    for (var index = 0; index < value.length; index++) {
      if (bytes[offset + index] != value.codeUnitAt(index)) return false;
    }
    return true;
  }
}
