import 'package:flutter/material.dart';
import 'package:shiftly/features/chat/domain/entities/chat_models.dart';
import 'package:shiftly/features/chat/presentation/screens/chat_recording_screen.dart';
import 'package:shiftly/features/chat/presentation/widgets/chat_conversation_view_mixin.dart';
import 'package:shiftly/features/chat/presentation/widgets/chat_message_composer.dart';
import 'package:shiftly/features/chat/presentation/widgets/chat_reply_preview.dart';

export 'chat_conversation_top_banners.dart';

List<Widget> buildChatConversationBottomSection(
  BuildContext context,
  ChatConversationViewMixin state,
  ChatGroup? group,
) => [
  if (state.reply != null)
    Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: ChatReplyPreview(
        name: state.reply!.sender.displayName,
        text: replyMessageText(state.reply!),
        onCancel: () => state.setReply(null),
      ),
    ),
  if (group?.isArchived != true)
    ChatMessageComposer(
      disabled: group?.isArchived == true,
      loadingAccess: group == null,
      textController: state.textController,
      savingText: state.savingText,
      mediaBusy: state.media.mediaBusy,
      recording: state.media.recording,
      hasPreparedMedia: state.media.hasPreparedMedia,
      recordingLabel: state.media.recordingLabel(),
      onTextChanged: state.refreshView,
      onSend: state.sendText,
      onRetryPrepared: state.media.retryPreparedMedia,
      onPickImage: state.media.pickImage,
      onPickDocument: state.media.pickDocument,
      onStartRecording: () async {
        await state.media.startRecording();
        if (context.mounted && state.media.recording) {
          await Navigator.push(
            context,
            MaterialPageRoute<void>(
              builder: (_) => ChatRecordingScreen(capture: state.media),
            ),
          );
        }
      },
      onShareLocation: state.media.shareLocation,
      onFinishRecording: state.media.finishRecording,
    ),
];
