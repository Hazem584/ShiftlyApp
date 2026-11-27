import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:record/record.dart';
import 'package:shiftly/core/storage/platform_file.dart';

mixin ChatMediaCaptureState on ChangeNotifier {
  final picker = ImagePicker();
  final recorder = AudioRecorder();
  Timer? recordTimer;
  DateTime? recordStarted;
  bool isRecording = false, isMediaBusy = false, isDisposed = false;
  Uint8List? preparedImage;
  String? preparedCaption, preparedVoicePath, recordPath;
  int? preparedVoiceDuration;

  bool get recording => isRecording;
  bool get mediaBusy => isMediaBusy;
  bool get hasPreparedMedia =>
      preparedImage != null || preparedVoicePath != null;

  void setMediaBusy(bool value) => notifyUpdate(() => isMediaBusy = value);
  void setRecording(bool value) => notifyUpdate(() => isRecording = value);
  void setRecordingSilent(bool value) => isRecording = value;
  void notifyChange() => notifyUpdate(() {});

  void setPreparedImage(Uint8List? bytes, String? caption) {
    preparedImage = bytes;
    preparedCaption = caption;
  }

  void setPreparedVoice(String? path, int? durationMs) {
    preparedVoicePath = path;
    preparedVoiceDuration = durationMs;
  }

  void startRecordTimer(VoidCallback onTick) {
    recordTimer?.cancel();
    recordTimer = Timer.periodic(const Duration(seconds: 1), (_) => onTick());
  }

  void stopRecordTimer() => recordTimer?.cancel();

  void notifyUpdate(VoidCallback change) {
    if (isDisposed) return;
    change();
    notifyListeners();
  }

  void clearPreparedMedia() {
    preparedImage = null;
    preparedCaption = null;
    deleteLocalMediaFile(preparedVoicePath);
    preparedVoicePath = null;
    preparedVoiceDuration = null;
  }

  void deleteLocalMediaFile(String? path) {
    if (path != null) {
      unawaited(
        ChatLocalFile(path)
            .delete()
            .catchError((Object _) => ChatLocalFile(path)),
      );
    }
  }
}
