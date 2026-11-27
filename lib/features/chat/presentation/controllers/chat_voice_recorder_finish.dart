import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/features/chat/presentation/controllers/chat_media_capture.dart';
import 'package:shiftly/features/chat/presentation/controllers/chat_voice_review_action.dart';
import 'package:shiftly/features/chat/presentation/cubit/chat_conversation_cubit.dart';
import 'package:shiftly/features/chat/presentation/dialogs/shiftly_chat_dialog.dart';

Future<void> finishChatRecording(
  ChatMediaCapture capture, {
  required bool send,
}) async {
  if (!capture.recording) return;
  final context = capture.context;
  final conversation = context.read<ChatConversationCubit>();
  final generation = conversation.generation;
  if (!send) {
    final discard = await ShiftlyChatDialog.confirm(
      context,
      title: 'Discard recording?',
      message: 'This voice recording will be permanently discarded.',
      confirmText: 'Discard',
      destructive: true,
    );
    if (!discard || !capture.active || !capture.recording) return;
  }
  final started = capture.recordStarted;
  capture.setRecording(false);
  capture.stopRecordTimer();
  String? path;
  var accepted = false;
  try {
    if (!send) return await capture.recorder.cancel();
    path = await capture.recorder.stop();
    if (path == null) throw const FormatException('Missing recording');
    final duration = started == null
        ? 0
        : DateTime.now().difference(started).inMilliseconds;
    accepted = await reviewAndSendChatVoice(
      capture,
      conversation,
      generation,
      path,
      duration,
    );
  } catch (_) {
    if (context.mounted && capture.active) {
      Fluttertoast.showToast(
        msg: context.tr('The recording could not be prepared.'),
      );
    }
  } finally {
    if (path != null && (accepted || capture.preparedVoicePath != path)) {
      capture.deleteLocalMediaFile(path);
    }
    capture.recordPath = null;
    capture.recordStarted = null;
    if (capture.active) capture.notifyChange();
  }
}
