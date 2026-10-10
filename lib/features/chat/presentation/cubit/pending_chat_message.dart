import 'dart:typed_data';

import 'package:equatable/equatable.dart';
import 'package:shiftly/core/error/failure.dart';
import 'package:shiftly/features/chat/domain/entities/chat_models.dart';

enum ChatUploadState {
  queued,
  sending,
  uncertain,
  preparing,
  uploading,
  finalizing,
  sent,
  failed,
  cancelled,
}

enum PendingChatMediaType {
  text,
  location,
  image,
  voice;

  String get apiValue => switch (this) {
    PendingChatMediaType.text => 'TEXT',
    PendingChatMediaType.location => 'LOCATION',
    PendingChatMediaType.image => 'IMAGE',
    PendingChatMediaType.voice => 'VOICE',
  };
}

class PendingChatMessage extends Equatable {
  const PendingChatMessage({
    required this.clientMessageId,
    required this.mediaType,
    required this.status,
    this.progress = 0,
    this.previewBytes,
    this.durationMs,
    this.failure,
    this.text,
    this.location,
    this.localPath,
    this.canCancel = true,
  });

  final String clientMessageId;
  final PendingChatMediaType mediaType;
  final ChatUploadState status;
  final double progress;
  final Uint8List? previewBytes;
  final int? durationMs;
  final Failure? failure;
  final String? text;
  final ChatLocation? location;
  final String? localPath;
  final bool canCancel;

  PendingChatMessage copyWith({
    ChatUploadState? status,
    double? progress,
    bool clearPreview = false,
    Failure? failure,
    bool clearFailure = false,
  }) => PendingChatMessage(
    clientMessageId: clientMessageId,
    mediaType: mediaType,
    status: status ?? this.status,
    progress: progress ?? this.progress,
    previewBytes: clearPreview ? null : previewBytes,
    durationMs: durationMs,
    failure: clearFailure ? null : failure ?? this.failure,
    text: text,
    location: location,
    localPath: localPath,
    canCancel: canCancel,
  );

  @override
  List<Object?> get props => [
    clientMessageId,
    mediaType,
    status,
    progress,
    previewBytes,
    durationMs,
    failure,
    text,
    location,
    localPath,
    canCancel,
  ];
}
