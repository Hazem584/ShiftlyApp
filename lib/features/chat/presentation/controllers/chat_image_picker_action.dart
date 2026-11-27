import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/features/chat/domain/services/chat_media_validation.dart';
import 'package:shiftly/features/chat/presentation/controllers/chat_media_capture.dart';
import 'package:shiftly/features/chat/presentation/cubit/chat_conversation_cubit.dart';
import 'package:shiftly/features/chat/presentation/screens/chat_media_review_screen.dart';

Future<void> pickChatImage(ChatMediaCapture capture) async {
  if (capture.mediaBusy) return;
  final context = capture.context;
  final conversation = context.read<ChatConversationCubit>();
  final generation = conversation.generation;
  capture.setMediaBusy(true);
  try {
    final selected = await capture.picker.pickImage(
      source: ImageSource.gallery,
    );
    if (selected == null || !capture.active) return;
    final length = await selected.length();
    if (length < 1 || length > ChatMediaValidation.imageMaxBytes) {
      if (context.mounted && capture.active) {
        Fluttertoast.showToast(
          msg: context.tr('Images must be 5 MiB or smaller.'),
        );
      }
      return;
    }
    final bytes = await selected.readAsBytes();
    if (ChatMediaValidation.imageMime(bytes) == null) {
      if (context.mounted && capture.active) {
        Fluttertoast.showToast(
          msg: context.tr('Choose a valid JPEG, PNG, or WebP image.'),
        );
      }
      return;
    }
    if (!context.mounted || !capture.active) return;
    final decision = await Navigator.push<ChatMediaDecision>(
      context,
      MaterialPageRoute(
        builder: (_) => ChatMediaReviewScreen(kind: 'IMAGE', bytes: bytes),
      ),
    );
    if (!capture.active ||
        conversation.generation != generation ||
        decision == null) {
      return;
    }
    if (decision.reselect) {
      capture.setMediaBusy(false);
      await capture.pickImage();
      return;
    }
    capture.setPreparedImage(bytes, decision.caption);
    final id = await conversation.sendImage(bytes, caption: decision.caption);
    if (id != null) capture.setPreparedImage(null, decision.caption);
  } catch (_) {
    if (context.mounted && capture.active) {
      Fluttertoast.showToast(
        msg: context.tr('The image could not be prepared.'),
      );
    }
  } finally {
    if (capture.active) capture.setMediaBusy(false);
  }
}
