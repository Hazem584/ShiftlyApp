import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:record/record.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/storage/platform_file.dart';
import 'package:shiftly/features/chat/domain/services/chat_media_validation.dart';
import 'package:shiftly/features/chat/presentation/controllers/chat_media_capture.dart';

Future<void> startChatRecording(ChatMediaCapture capture) async {
  if (capture.recording || capture.mediaBusy) return;
  final context = capture.context;
  capture.setMediaBusy(true);
  try {
    if (!await capture.recorder.hasPermission()) {
      if (context.mounted && capture.active) {
        Fluttertoast.showToast(
          msg: context.tr('Microphone permission is required to record.'),
        );
      }
      return;
    }
    final path = await chatRecordingPath();
    capture.recordPath = path;
    final opus =
        kIsWeb && await capture.recorder.isEncoderSupported(AudioEncoder.opus);
    await capture.recorder.start(
      RecordConfig(encoder: opus ? AudioEncoder.opus : AudioEncoder.aacLc),
      path: path,
    );
    capture.recordStarted = DateTime.now();
    capture.startRecordTimer(() {
      if (!capture.active || !capture.recording) return;
      final elapsed = DateTime.now().difference(capture.recordStarted!);
      capture.notifyChange();
      if (elapsed.inMilliseconds >= ChatMediaValidation.voiceMaxDurationMs) {
        unawaited(capture.finishRecording(send: true));
      }
    });
    if (capture.active) capture.setRecording(true);
  } catch (_) {
    if (context.mounted && capture.active) {
      Fluttertoast.showToast(
        msg: context.tr('Recording could not be started.'),
      );
    }
  } finally {
    if (capture.active) capture.setMediaBusy(false);
  }
}

Future<void> handleChatRecordingInterruption(ChatMediaCapture capture) async {
  final context = capture.context;
  if (!capture.recording) return;
  capture.stopRecordTimer();
  capture.setRecordingSilent(false);
  final path = capture.recordPath;
  capture.recordPath = null;
  capture.recordStarted = null;
  try {
    await capture.recorder.cancel();
  } catch (_) {}
  if (path != null) {
    try {
      await ChatLocalFile(path).delete();
    } catch (_) {}
  }
  if (context.mounted && capture.active) {
    capture.notifyChange();
    if (context.mounted && capture.active) {
      Fluttertoast.showToast(msg: context.tr('Recording was interrupted.'));
    }
  }
}
