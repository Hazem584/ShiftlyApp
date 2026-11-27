import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/storage/platform_file.dart';
import 'package:shiftly/features/chat/domain/services/chat_media_validation.dart';
import 'package:shiftly/features/chat/presentation/controllers/chat_media_capture.dart';
import 'package:shiftly/features/chat/presentation/cubit/chat_conversation_cubit.dart';
import 'package:shiftly/features/chat/presentation/screens/chat_media_review_screen.dart';

Future<bool> reviewAndSendChatVoice(
  ChatMediaCapture capture,
  ChatConversationCubit conversation,
  int generation,
  String path,
  int duration,
) async {
  final context = capture.context;
  final bytes = await ChatLocalFile(path).readAsBytes();
  final mime = ChatMediaValidation.voiceMime(bytes) ?? '';
  if (!ChatMediaValidation.validVoice(
    bytes: bytes,
    mimeType: mime,
    durationMs: duration,
  )) {
    if (context.mounted && capture.active) {
      Fluttertoast.showToast(
        msg: context.tr('The recording is empty, invalid, or too long.'),
      );
    }
    return false;
  }
  if (!context.mounted || !capture.active) return false;
  final decision = await Navigator.push<ChatMediaDecision>(
    context,
    MaterialPageRoute(
      builder: (_) => ChatMediaReviewScreen(
        kind: 'VOICE',
        voicePath: path,
        durationMs: duration,
      ),
    ),
  );
  if (!capture.active ||
      conversation.generation != generation ||
      decision == null) {
    return false;
  }
  capture.setPreparedVoice(path, duration);
  final id = await conversation.sendVoice(
    mimeType: mime,
    bytes: bytes,
    durationMs: duration,
  );
  if (id != null) capture.setPreparedVoice(null, null);
  return id != null;
}
