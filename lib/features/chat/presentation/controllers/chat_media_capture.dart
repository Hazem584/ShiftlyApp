import 'dart:async';

import 'package:flutter/material.dart';
import 'package:record/record.dart';

import 'chat_document_picker_action.dart';
import 'chat_image_picker_action.dart';
import 'chat_location_share_action.dart';
import 'chat_media_capture_state.dart';
import 'chat_prepared_media_retry.dart';
import 'chat_voice_recorder_finish.dart';
import 'chat_voice_recorder_start.dart';

class ChatMediaCapture extends ChangeNotifier with ChatMediaCaptureState {
  ChatMediaCapture(this.context) {
    _recordState = recorder.onStateChanged().listen((value) {
      if ((value == RecordState.stop || value == RecordState.pause) &&
          isRecording) {
        unawaited(handleRecordingInterruption());
      }
    });
  }
  final BuildContext context;
  StreamSubscription<RecordState>? _recordState;
  bool get active => context.mounted && !isDisposed;

  @override
  void dispose() {
    isDisposed = true;
    recordTimer?.cancel();
    unawaited(_recordState?.cancel());
    unawaited(recorder.cancel());
    recorder.dispose();
    clearPreparedMedia();
    deleteLocalMediaFile(recordPath);
    super.dispose();
  }

  Future<void> pickImage() => pickChatImage(this);
  Future<void> pickDocument() => pickChatDocument(this);
  Future<void> startRecording() => startChatRecording(this);
  Future<void> finishRecording({required bool send}) =>
      finishChatRecording(this, send: send);
  Future<void> handleRecordingInterruption() =>
      handleChatRecordingInterruption(this);
  Future<void> retryPreparedMedia() => retryChatPreparedMedia(this);
  Future<void> shareLocation() => shareChatLocation(this);

  String recordingLabel() {
    final elapsed = recordStarted == null
        ? Duration.zero
        : DateTime.now().difference(recordStarted!);
    final m = elapsed.inMinutes.toString().padLeft(2, '0');
    final s = (elapsed.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s / 10:00';
  }
}
