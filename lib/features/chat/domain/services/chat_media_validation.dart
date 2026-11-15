import 'dart:typed_data';

import 'chat_image_validation.dart';
import 'chat_media_limits.dart';
import 'chat_voice_validation.dart';

abstract final class ChatMediaValidation {
  static const imageMaxBytes = ChatMediaLimits.imageMaxBytes;
  static const voiceMaxBytes = ChatMediaLimits.voiceMaxBytes;
  static const voiceMaxDurationMs = ChatMediaLimits.voiceMaxDurationMs;
  static String? voiceMime(Uint8List bytes) => detectChatVoiceMime(bytes);
  static String? imageMime(Uint8List bytes) => detectChatImageMime(bytes);
  static bool validVoice({
    required Uint8List bytes,
    required String mimeType,
    required int durationMs,
  }) =>
      validChatVoice(bytes: bytes, mimeType: mimeType, durationMs: durationMs);
}
