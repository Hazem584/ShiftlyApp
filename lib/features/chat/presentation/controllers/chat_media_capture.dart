import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/features/chat/domain/entities/chat_models.dart';
import 'package:shiftly/features/chat/domain/services/chat_media_validation.dart';
import 'package:shiftly/features/chat/presentation/cubit/chat_conversation_cubit.dart';
import 'package:shiftly/features/chat/presentation/dialogs/shiftly_chat_dialog.dart';

class ChatMediaCapture extends ChangeNotifier {
  ChatMediaCapture(this.context) {
    _recordState = _recorder.onStateChanged().listen((value) {
      if ((value == RecordState.stop || value == RecordState.pause) &&
          _recording) {
        unawaited(handleRecordingInterruption());
      }
    });
  }
  final BuildContext context;
  final _picker = ImagePicker();
  final _recorder = AudioRecorder();
  StreamSubscription<RecordState>? _recordState;
  Timer? _recordTimer;
  DateTime? _recordStarted;
  bool _recording = false;
  bool _mediaBusy = false;
  bool _disposed = false;
  Uint8List? _preparedImage;
  String? _preparedVoicePath;
  int? _preparedVoiceDuration;
  String? _recordPath;
  bool get recording => _recording;
  bool get mediaBusy => _mediaBusy;
  bool get hasPreparedMedia =>
      _preparedImage != null || _preparedVoicePath != null;
  void _update(VoidCallback change) {
    if (_disposed) return;
    change();
    notifyListeners();
  }

  void clearPreparedMedia() {
    _preparedImage = null;
    if (_preparedVoicePath case final path?) {
      unawaited(File(path).delete().catchError((Object _) => File(path)));
    }
    _preparedVoicePath = null;
    _preparedVoiceDuration = null;
  }

  @override
  void dispose() {
    _disposed = true;
    _recordTimer?.cancel();
    unawaited(_recordState?.cancel());
    unawaited(_recorder.cancel());
    _recorder.dispose();
    clearPreparedMedia();
    if (_recordPath case final path?) {
      unawaited(File(path).delete().catchError((Object _) => File(path)));
    }
    super.dispose();
  }

  Future<void> pickImage() async {
    if (_mediaBusy) return;
    _update(() => _mediaBusy = true);
    try {
      final selected = await _picker.pickImage(source: ImageSource.gallery);
      if (selected == null || !(context.mounted && !_disposed)) return;
      final length = await selected.length();
      if (length < 1 || length > ChatMediaValidation.imageMaxBytes) {
        if (!(context.mounted && !_disposed)) return;
        Fluttertoast.showToast(
          msg: context.tr('Images must be 5 MiB or smaller.'),
        );
        return;
      }
      final bytes = await selected.readAsBytes();
      final mime = ChatMediaValidation.imageMime(bytes);
      if (mime == null) {
        if (!(context.mounted && !_disposed)) return;
        Fluttertoast.showToast(
          msg: context.tr('Choose a valid JPEG, PNG, or WebP image.'),
        );
        return;
      }
      if ((context.mounted && !_disposed)) {
        _preparedImage = bytes;
        final id = await context.read<ChatConversationCubit>().sendImage(bytes);
        if (id != null) _preparedImage = null;
      }
    } catch (_) {
      if (!(context.mounted && !_disposed)) return;
      Fluttertoast.showToast(
        msg: context.tr('The image could not be prepared.'),
      );
    } finally {
      if ((context.mounted && !_disposed)) _update(() => _mediaBusy = false);
    }
  }

  Future<void> startRecording() async {
    if (_recording || _mediaBusy) return;
    _update(() => _mediaBusy = true);
    try {
      if (!await _recorder.hasPermission()) {
        if (!(context.mounted && !_disposed)) return;
        Fluttertoast.showToast(
          msg: context.tr('Microphone permission is required to record.'),
        );
        return;
      }
      final directory = await getTemporaryDirectory();
      final path =
          '${directory.path}${Platform.pathSeparator}shiftly-voice-${DateTime.now().microsecondsSinceEpoch}.m4a';
      _recordPath = path;
      await _recorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc),
        path: path,
      );
      _recordStarted = DateTime.now();
      _recordTimer?.cancel();
      _recordTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!(context.mounted && !_disposed) || !_recording) return;
        final elapsed = DateTime.now().difference(_recordStarted!);
        _update(() {});
        if (elapsed.inMilliseconds >= ChatMediaValidation.voiceMaxDurationMs) {
          unawaited(finishRecording(send: true));
        }
      });
      if ((context.mounted && !_disposed)) _update(() => _recording = true);
    } catch (_) {
      if (!(context.mounted && !_disposed)) return;
      Fluttertoast.showToast(
        msg: context.tr('Recording could not be started.'),
      );
    } finally {
      if ((context.mounted && !_disposed)) _update(() => _mediaBusy = false);
    }
  }

  Future<void> finishRecording({required bool send}) async {
    if (!_recording) return;
    if (!send) {
      final discard = await ShiftlyChatDialog.confirm(
        context,
        title: 'Discard recording?',
        message: 'This voice recording will be permanently discarded.',
        confirmText: 'Discard',
        destructive: true,
      );
      if (!discard || !(context.mounted && !_disposed) || !_recording) return;
    }
    final started = _recordStarted;
    _update(() => _recording = false);
    _recordTimer?.cancel();
    String? path;
    bool accepted = false;
    try {
      if (!send) {
        await _recorder.cancel();
        return;
      }
      path = await _recorder.stop();
      final duration = started == null
          ? 0
          : DateTime.now().difference(started).inMilliseconds;
      if (path == null) throw const FormatException('Missing recording');
      final file = File(path);
      final bytes = await file.readAsBytes();
      if (!ChatMediaValidation.validVoice(
        bytes: bytes,
        mimeType: 'audio/mp4',
        durationMs: duration,
      )) {
        if (!(context.mounted && !_disposed)) return;
        Fluttertoast.showToast(
          msg: context.tr('The recording is empty, invalid, or too long.'),
        );
        return;
      }
      if ((context.mounted && !_disposed)) {
        _preparedVoicePath = path;
        _preparedVoiceDuration = duration;
        final id = await context.read<ChatConversationCubit>().sendVoice(
          mimeType: 'audio/mp4',
          bytes: bytes,
          durationMs: duration,
        );
        accepted = id != null;
        if (accepted) {
          _preparedVoicePath = null;
          _preparedVoiceDuration = null;
        }
      }
    } catch (_) {
      if (!(context.mounted && !_disposed)) return;
      Fluttertoast.showToast(
        msg: context.tr('The recording could not be prepared.'),
      );
    } finally {
      if (path != null && (accepted || _preparedVoicePath != path)) {
        try {
          await File(path).delete();
        } catch (_) {}
      }
      _recordPath = null;
      _recordStarted = null;
      if ((context.mounted && !_disposed)) _update(() {});
    }
  }

  Future<void> handleRecordingInterruption() async {
    if (!_recording) return;
    _recordTimer?.cancel();
    _recording = false;
    final path = _recordPath;
    _recordPath = null;
    _recordStarted = null;
    try {
      await _recorder.cancel();
    } catch (_) {}
    if (path != null) {
      try {
        await File(path).delete();
      } catch (_) {}
    }
    if ((context.mounted && !_disposed)) {
      _update(() {});
      if (!(context.mounted && !_disposed)) return;
      Fluttertoast.showToast(msg: context.tr('Recording was interrupted.'));
    }
  }

  Future<void> retryPreparedMedia() async {
    _update(() => _mediaBusy = true);
    try {
      final conversation = context.read<ChatConversationCubit>();
      if (_preparedImage case final bytes?) {
        if (await conversation.sendImage(bytes) != null) _preparedImage = null;
      }
      if (_preparedVoicePath case final path?) {
        final bytes = await File(path).readAsBytes();
        if (await conversation.sendVoice(
              bytes: bytes,
              mimeType: 'audio/mp4',
              durationMs: _preparedVoiceDuration!,
            ) !=
            null) {
          await File(path).delete();
          _preparedVoicePath = null;
          _preparedVoiceDuration = null;
        }
      }
    } catch (_) {
      if (!(context.mounted && !_disposed)) return;
      Fluttertoast.showToast(
        msg: context.tr(
          'Media could not be saved. Retry when storage is available.',
        ),
      );
    } finally {
      if ((context.mounted && !_disposed)) _update(() => _mediaBusy = false);
    }
  }

  String recordingLabel() {
    final elapsed = _recordStarted == null
        ? Duration.zero
        : DateTime.now().difference(_recordStarted!);
    final minutes = elapsed.inMinutes.toString().padLeft(2, '0');
    final seconds = (elapsed.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds / 10:00';
  }

  Future<void> shareLocation() async {
    if (_mediaBusy) return;
    _update(() => _mediaBusy = true);
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        if (!(context.mounted && !_disposed)) return;
        Fluttertoast.showToast(
          msg: context.tr('Turn on location services to share a location.'),
        );
        return;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (!(context.mounted && !_disposed)) return;
        Fluttertoast.showToast(
          msg: context.tr(
            permission == LocationPermission.deniedForever
                ? 'Location permission is blocked in system settings.'
                : 'Location permission was denied.',
          ),
        );
        return;
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      final location = ChatLocation(
        latitude: _sixDecimals(position.latitude),
        longitude: _sixDecimals(position.longitude),
      );
      if (!location.isValid || !(context.mounted && !_disposed)) return;
      final confirmed = await ShiftlyChatDialog.confirm(
        context,
        title: 'Share this location?',
        message: 'Your current coordinates will be visible to this group.',
        confirmText: 'Share',
      );
      if (confirmed && (context.mounted && !_disposed)) {
        await context.read<ChatConversationCubit>().sendLocation(location);
      }
    } on TimeoutException {
      if (!(context.mounted && !_disposed)) return;
      Fluttertoast.showToast(msg: context.tr('Location request timed out.'));
    } catch (_) {
      if (!(context.mounted && !_disposed)) return;
      Fluttertoast.showToast(
        msg: context.tr('Your location is currently unavailable.'),
      );
    } finally {
      if ((context.mounted && !_disposed)) _update(() => _mediaBusy = false);
    }
  }

  double _sixDecimals(double value) =>
      (value * 1000000).roundToDouble() / 1000000;
}
