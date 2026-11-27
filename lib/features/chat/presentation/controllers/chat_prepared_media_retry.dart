import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/storage/platform_file.dart';
import 'package:shiftly/features/chat/domain/services/chat_media_validation.dart';
import 'package:shiftly/features/chat/presentation/controllers/chat_media_capture.dart';
import 'package:shiftly/features/chat/presentation/cubit/chat_conversation_cubit.dart';

Future<void> retryChatPreparedMedia(ChatMediaCapture capture) async {
  final context = capture.context;
  capture.setMediaBusy(true);
  try {
    final conversation = context.read<ChatConversationCubit>();
    if (capture.preparedImage case final bytes?) {
      final id = await conversation.sendImage(
        bytes,
        caption: capture.preparedCaption,
      );
      if (id != null) capture.setPreparedImage(null, capture.preparedCaption);
    }
    if (capture.preparedVoicePath case final path?) {
      final bytes = await ChatLocalFile(path).readAsBytes();
      final id = await conversation.sendVoice(
        bytes: bytes,
        mimeType: ChatMediaValidation.voiceMime(bytes) ?? '',
        durationMs: capture.preparedVoiceDuration!,
      );
      if (id != null) {
        await ChatLocalFile(path).delete();
        capture.setPreparedVoice(null, null);
      }
    }
  } catch (_) {
    if (context.mounted && capture.active) {
      Fluttertoast.showToast(
        msg: context.tr(
          'Media could not be saved. Retry when storage is available.',
        ),
      );
    }
  } finally {
    if (capture.active) capture.setMediaBusy(false);
  }
}
